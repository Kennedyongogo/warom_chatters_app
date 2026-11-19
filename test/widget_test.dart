import 'package:flutter_test/flutter_test.dart';
import 'package:mtaani/models/account.dart';
import 'package:mtaani/models/profile.dart';
import 'package:mtaani/services/mtaani_api.dart';

void main() {
  final api = MtaaniApi.instance;

  setUp(api.reset);

  test('provider signup can complete onboarding without dating preferences', () async {
    final outcome = await api.continueWithProvider(AuthProvider.google);
    expect(outcome.isNewAccount, isTrue);

    await api.acceptTerms(marketingOptIn: false);
    await api.submitBirthDate(DateTime(1998, 4, 2));
    await api.saveBasics(name: 'Amina', gender: Gender.woman, showMe: ShowMe.men);
    await api.savePhotos(['assets/images/profiles/amani.jpg']);
    await api.saveAbout(bio: 'Love hiking and good food.', interests: ['Hiking', 'Food', 'Music']);
    await api.saveLocation(Area.all.first, fromDevice: false);
    await api.activateProfile();

    expect(api.me!.discoverable, isTrue);
    expect(api.account!.step, OnboardingStep.done);
  });
}
