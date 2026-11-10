import 'package:flutter_test/flutter_test.dart';
import 'package:mtaani/models/account.dart';
import 'package:mtaani/models/profile.dart';
import 'package:mtaani/models/social.dart';
import 'package:mtaani/services/mtaani_api.dart';

void main() {
  final api = MtaaniApi.instance;
  const kenya = Country('Kenya', '+254', '');

  setUp(api.reset);

  Future<AuthOutcome> signIn(String phone, {bool create = false}) async {
    await api.requestPhoneCode(phone);
    return api.verifyPhoneCode(phone, MtaaniApi.demoCode, createIfMissing: create);
  }

  group('registration', () {
    test('phone numbers are normalised to +254 format', () {
      expect(MtaaniApi.normalizePhone(kenya, '0712 345 678'), '+254712345678');
      expect(MtaaniApi.normalizePhone(kenya, '+254 712345678'), '+254712345678');
      expect(MtaaniApi.normalizePhone(kenya, '0112345678'), '+254112345678');
      expect(MtaaniApi.normalizePhone(kenya, '12345'), isNull);
    });

    test('wrong codes are limited and resends are rate limited', () async {
      await api.requestPhoneCode('+254700000001');
      await expectLater(
        api.verifyPhoneCode('+254700000001', '000000', createIfMissing: true),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('4 attempts left'))),
      );
      await expectLater(api.requestPhoneCode('+254700000001'), throwsA(isA<ApiException>()));
    });

    test('logging in with an unknown number does not create an account', () async {
      await expectLater(
        signIn('+254700000002'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.noAccount)),
      );
      expect(api.account, isNull);
    });

    test('steps cannot be skipped and under-18s are stopped', () async {
      final outcome = await signIn('+254700000003', create: true);
      expect(outcome.isNewAccount, isTrue);
      expect(outcome.account.step, OnboardingStep.email);

      await expectLater(
        api.saveBasics(name: 'Amina', gender: Gender.woman, showMe: ShowMe.men),
        throwsA(isA<ApiException>()),
      );

      await api.skipEmail();
      await api.acceptTerms(marketingOptIn: false);
      expect(api.account!.termsVersion, MtaaniApi.termsVersion);
      expect(api.account!.termsAcceptedAt, isNotNull);

      await expectLater(
        api.submitBirthDate(DateTime(DateTime.now().year - 16)),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', ApiException.ineligible)),
      );
      expect(api.account!.status, AccountStatus.ineligible);
      await expectLater(api.submitBirthDate(DateTime(1995)), throwsA(isA<ApiException>()));
    });

    test('a completed onboarding becomes discoverable only after activation', () async {
      await signIn('+254700000004', create: true);
      await api.skipEmail();
      await api.acceptTerms(marketingOptIn: true);
      await api.submitBirthDate(DateTime(1998, 4, 2));
      await api.saveBasics(name: 'Amina', gender: Gender.woman, showMe: ShowMe.men);
      await api.savePhotos(['assets/images/profiles/amani.jpg']);
      await api.saveAbout(bio: 'Love hiking and good food.', interests: ['Hiking', 'Food', 'Music']);
      await api.savePreferences(minAge: 24, maxAge: 35, maxDistanceKm: 30);
      await api.saveLocation(Area.all.first, fromDevice: false);

      expect(api.me!.discoverable, isFalse);
      await expectLater(api.discover(), throwsA(isA<ApiException>()));

      await api.activateProfile();
      expect(api.me!.discoverable, isTrue);
      expect(api.account!.step, OnboardingStep.done);
      expect((await api.discover(limit: 20)).map((p) => p.id), contains('brian'));
    });
  });

  group('matching', () {
    test('liking someone who already liked you creates exactly one match', () async {
      await signIn(MtaaniApi.demoPhone);

      final first = await api.swipe('wanjiru', SwipeAction.like);
      expect(first.matched, isFalse);

      final mutual = await api.swipe('achieng', SwipeAction.like);
      expect(mutual.matched, isTrue);

      final retried = await api.swipe('achieng', SwipeAction.like);
      expect(retried.match?.id, mutual.match!.id);
      expect(api.matches, hasLength(1));
    });

    test('discovery applies both people\'s preferences and hides swiped profiles', () async {
      await signIn(MtaaniApi.demoPhone);

      final ids = (await api.discover(limit: 20)).map((p) => p.id).toSet();
      expect(ids, containsAll(['wanjiru', 'achieng', 'zawadi', 'njeri', 'amani']));
      expect(ids, isNot(anyOf(contains('brian'), contains('faith'), contains('mercy'), contains('grace'))));

      await api.swipe('wanjiru', SwipeAction.pass);
      expect((await api.discover(limit: 20)).map((p) => p.id), isNot(contains('wanjiru')));
    });

    test('blocking ends the match and stops messages', () async {
      await signIn(MtaaniApi.demoPhone);
      final match = (await api.swipe('achieng', SwipeAction.like)).match!;
      await api.sendMessage(match.id, 'Hi Achieng');

      await api.block('achieng');

      expect(api.matches, isEmpty);
      await expectLater(api.sendMessage(match.id, 'Still there?'), throwsA(isA<ApiException>()));
    });
  });
}
