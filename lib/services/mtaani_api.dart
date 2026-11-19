import 'dart:async';
import 'dart:math' as math;

import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/profile.dart';
import '../models/social.dart';
import 'seed_data.dart';
import 'warom_auth.dart';

class _PendingCode {
  final String code;
  final DateTime expiresAt;
  int attempts = 0;

  _PendingCode(this.code, this.expiresAt);
}

/// In-memory stand-in for the Mtaani backend.
///
/// Screens may only call these methods; every rule (discovery filters, match creation, chat
/// permissions, blocking) is enforced here, never in the UI. A real server replaces this class
/// with HTTP and websocket calls that have the same shape.
class MtaaniApi extends ChangeNotifier {
  MtaaniApi._() {
    reset();
  }

  static final instance = MtaaniApi._();

  static const _latency = Duration(milliseconds: 350);
  static const maxMessageLength = 1000;

  /// Every code is this value in the prototype; production sends a random code by SMS or email.
  static const demoCode = '123456';
  static const termsVersion = '2026-10';
  static const _codeLifetime = Duration(minutes: 5);
  static const _maxCodeAttempts = 5;

  final _random = math.Random();

  late Map<String, Profile> _profiles;
  late Map<String, int> _rank;
  late Map<String, Interaction> _interactions;
  late Map<String, Match> _matches;
  late Set<String> _blocks;
  late Map<String, List<Message>> _messages;
  late Map<String, int> _replyCursor;
  late Map<String, Account> _accounts;
  late Map<String, (String email, _PendingCode code)> _emailCodes;
  late Set<String> _typing;
  late int _reports;
  late int _seq;
  int _discoveryVersion = 0;
  final List<Timer> _timers = [];
  String? _sessionUserId;

  bool _simulateNetworkFailure = false;

  /// Demo control: makes every request fail so the pitch can show that swipes are never silently lost.
  bool get simulateNetworkFailure => _simulateNetworkFailure;

  set simulateNetworkFailure(bool value) {
    _simulateNetworkFailure = value;
    notifyListeners();
  }

  void reset() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    final seeds = buildSeedProfiles();
    _profiles = {for (final p in seeds) p.id: p};
    _rank = {for (var i = 0; i < seeds.length; i++) seeds[i].id: i};
    _interactions = {};
    _matches = {};
    _blocks = {};
    _messages = {};
    _replyCursor = {};
    _accounts = {};
    _emailCodes = {};
    _typing = {};
    _reports = 0;
    _seq = 0;
    _sessionUserId = null;
    _simulateNetworkFailure = false;
    WaromAuth.instance.clear();
    _seedDemoMember();
    _discoveryVersion++;
    notifyListeners();
  }

  /// Demo chatter already through onboarding (local seed only).
  void _seedDemoMember() {
    final juma = buildDemoMember();
    _profiles[juma.id] = juma;
    _accounts[juma.id] = Account(
      id: juma.id,
      provider: AuthProvider.email,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      email: 'demo.chatter@warom.app',
      emailVerified: true,
      phoneVerified: false,
      termsVersion: termsVersion,
      termsAcceptedAt: DateTime.now().subtract(const Duration(days: 30)),
      step: OnboardingStep.done,
      status: AccountStatus.active,
    );
    _seedIncomingLikes(juma);
  }

  /// Bumped whenever the candidate pool may have changed, so Discover knows to reload its queue.
  int get discoveryVersion => _discoveryVersion;

  // ---------------------------------------------------------------- session

  Profile? get me => _sessionUserId == null ? null : _profiles[_sessionUserId];

  Account? get account => _sessionUserId == null ? null : _accounts[_sessionUserId];

  Future<void> logOut() async {
    _sessionUserId = null;
    await WaromAuth.instance.clear();
    notifyListeners();
  }

  /// Bridges a WAROM API session into the local in-app session/onboarding flow.
  AuthOutcome adoptRemoteUser({
    required Map<String, dynamic> user,
    required AuthProvider provider,
    required bool isNew,
  }) {
    final id = '${user['id']}';
    final username = '${user['username'] ?? ''}'.trim();
    final email = user['email'] as String?;
    final completed = user['onboarding_completed'] == true;
    final dobRaw = user['date_of_birth'] as String?;
    final genderRaw = '${user['gender'] ?? ''}'.toLowerCase();
    final hobbies = (user['hobbies'] is List)
        ? (user['hobbies'] as List).map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : <String>[];
    final bio = '${user['bio'] ?? ''}';
    final city = '${user['city'] ?? ''}';
    final country = '${user['country'] ?? ''}';
    final picture = user['profile_picture'] as String?;
    final covers = (user['cover_photos'] is List)
        ? (user['cover_photos'] as List).map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : <String>[];
    final photos = (user['photos'] is List)
        ? (user['photos'] as List).map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : <String>[];

    DateTime birthDate = DateTime(DateTime.now().year - 25);
    if (dobRaw != null && dobRaw.isNotEmpty) {
      birthDate = DateTime.tryParse(dobRaw) ?? birthDate;
    }

    Gender gender = Gender.man;
    if (genderRaw.contains('woman') || genderRaw == 'female' || genderRaw == 'f') {
      gender = Gender.woman;
    }

    final areaName = city.isNotEmpty
        ? (country.isNotEmpty ? '$city, $country' : city)
        : Area.all.first.name;
    Area area = Area(areaName, Area.all.first.lat, Area.all.first.lng);
    if (city.isNotEmpty) {
      for (final candidate in Area.all) {
        if (candidate.name.toLowerCase().contains(city.toLowerCase())) {
          area = candidate;
          break;
        }
      }
    }

    final imageList = <String>[
      if (picture != null && picture.isNotEmpty) picture,
      ...photos,
      ...covers,
    ];

    _profiles[id] = Profile(
      id: id,
      name: username.isNotEmpty ? username : (email?.split('@').first ?? 'Chatter'),
      birthDate: birthDate,
      gender: gender,
      showMe: ShowMe.everyone,
      bio: bio,
      interests: hobbies,
      photos: imageList,
      area: area,
      discoverable: completed,
      active: true,
    );

    final account = Account(
      id: id,
      provider: provider,
      createdAt: DateTime.now(),
      email: email,
      emailVerified: email != null && email.isNotEmpty,
      phoneVerified: false,
      termsVersion: completed ? termsVersion : null,
      termsAcceptedAt: completed ? DateTime.now() : null,
      step: completed ? OnboardingStep.done : OnboardingStep.terms,
      status: completed ? AccountStatus.active : AccountStatus.onboarding,
    );
    _accounts[id] = account;
    _sessionUserId = id;
    notifyListeners();
    return AuthOutcome(account, isNew);
  }

  /// Simulates the Google / Apple consent sheet; the provider vouches for the email address.
  Future<AuthOutcome> continueWithProvider(AuthProvider provider) async {
    await _roundTrip();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final email = 'demo.${provider.name}@warom.app';
    final existing = _accounts.values.where((a) => a.email == email).firstOrNull;
    if (existing != null) return _startSession(existing, isNew: false);
    final account = _newAccount(provider)
      ..email = email
      ..emailVerified = true
      ..step = OnboardingStep.terms;
    return _startSession(account, isNew: true);
  }

  Account _newAccount(AuthProvider provider) {
    final id = 'member_${++_seq}';
    final account = Account(id: id, provider: provider, createdAt: DateTime.now());
    _accounts[id] = account;
    _profiles[id] = Profile(
      id: id,
      name: '',
      birthDate: DateTime(DateTime.now().year - 25),
      gender: Gender.man,
      showMe: ShowMe.women,
      area: Area.all.first,
      discoverable: false,
    );
    return account;
  }

  AuthOutcome _startSession(Account account, {required bool isNew}) {
    _sessionUserId = account.id;
    notifyListeners();
    return AuthOutcome(account, isNew);
  }

  void _checkCode(_PendingCode? pending, String code) {
    if (pending == null) throw const ApiException('Request a new code to continue.');
    if (pending.attempts >= _maxCodeAttempts) {
      throw const ApiException('Too many incorrect attempts. Request a new code.');
    }
    if (DateTime.now().isAfter(pending.expiresAt)) throw const ApiException('This code has expired. Request a new one.');
    if (pending.code != code.trim()) {
      pending.attempts++;
      final left = _maxCodeAttempts - pending.attempts;
      throw ApiException(left == 0 ? 'Incorrect code. Request a new one.' : 'Incorrect code. $left attempts left.');
    }
  }

  // ------------------------------------------------------------ onboarding

  Future<void> requestEmailCode(String email) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.email);
    final normalized = email.trim().toLowerCase();
    if (!EmailValidator.validate(normalized)) throw const ApiException('Enter a valid email address.');
    final taken = _accounts.values.any((a) => a.id != account.id && a.email == normalized);
    // Same response either way, so the form can't be used to discover who has an account.
    _emailCodes[account.id] = (normalized, _PendingCode(taken ? '' : demoCode, DateTime.now().add(_codeLifetime)));
  }

  Future<void> verifyEmailCode(String code) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.email);
    final pending = _emailCodes[account.id];
    _checkCode(pending?.$2, code);
    _emailCodes.remove(account.id);
    account
      ..email = pending!.$1
      ..emailVerified = true;
    _advance(account, OnboardingStep.terms);
  }

  Future<void> skipEmail() async {
    await _roundTrip();
    _advance(_requireOnboarding(OnboardingStep.email), OnboardingStep.terms);
  }

  Future<void> acceptTerms({required bool marketingOptIn}) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.terms)
      ..termsVersion = termsVersion
      ..termsAcceptedAt = DateTime.now()
      ..marketingOptIn = marketingOptIn;
    _advance(account, OnboardingStep.birthDate);
  }

  /// Age is always calculated here from the date of birth, never taken from the client.
  Future<void> submitBirthDate(DateTime birthDate) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.birthDate);
    final now = DateTime.now();
    if (birthDate.isAfter(now)) throw const ApiException('Enter a valid date of birth.');
    final profile = _profiles[account.id]!..birthDate = birthDate;
    if (profile.age < 18) {
      account.status = AccountStatus.ineligible;
      notifyListeners();
      throw const ApiException('Warom is only for adults aged 18 and over.', code: ApiException.ineligible);
    }
    _advance(account, OnboardingStep.basics);
  }

  Future<void> saveBasics({required String name, required Gender gender, required ShowMe showMe}) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.basics);
    final clean = name.trim();
    if (clean.length < 2 || clean.length > 30) throw const ApiException('Enter a first name between 2 and 30 letters.');
    _profiles[account.id]!
      ..name = clean
      ..gender = gender
      ..showMe = showMe;
    _advance(account, OnboardingStep.photos);
  }

  /// Stores the picked image in protected storage and returns the stored reference.
  Future<String> uploadPhoto(String localPath) async {
    await _roundTrip();
    _requireMe();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return localPath;
  }

  Future<void> savePhotos(List<String> photos) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.photos);
    if (photos.isEmpty) throw const ApiException('Add at least one photo.');
    if (photos.length > 6) throw const ApiException('You can add up to 6 photos.');
    _profiles[account.id]!.photos = [...photos];
    _advance(account, OnboardingStep.about);
  }

  Future<void> saveAbout({required String bio, required List<String> interests, String? work}) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.about);
    _validateAbout(bio, interests);
    _profiles[account.id]!
      ..bio = bio.trim()
      ..interests = [...interests]
      ..work = (work?.trim().isEmpty ?? true) ? null : work!.trim();
    _advance(account, OnboardingStep.location);
  }

  Future<void> saveLocation(Area area, {required bool fromDevice}) async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.location)..locationFromDevice = fromDevice;
    _profiles[account.id]!.area = area;
    _advance(account, OnboardingStep.activate);
  }

  /// Final server-side gate: only a fully verified, eligible and complete profile becomes discoverable.
  Future<void> activateProfile() async {
    await _roundTrip();
    final account = _requireOnboarding(OnboardingStep.activate);
    final profile = _profiles[account.id]!;
    if (!account.emailVerified && account.provider == AuthProvider.email) {
      throw const ApiException('Verify your email first.');
    }
    if (account.termsVersion != termsVersion) throw const ApiException('Please accept the latest terms.');
    if (profile.age < 18) throw const ApiException('Warom is only for adults aged 18 and over.', code: ApiException.ineligible);
    if (profile.name.isEmpty || profile.photos.isEmpty) throw const ApiException('Your profile is missing details.');
    _validateAbout(profile.bio, profile.interests);
    profile.discoverable = true;
    account
      ..step = OnboardingStep.done
      ..status = AccountStatus.active;
    _seedIncomingLikes(profile);
    _discoveryVersion++;
    notifyListeners();
  }

  /// Rejects calls from ineligible accounts and calls that try to skip ahead of [step].
  Account _requireOnboarding(OnboardingStep step) {
    final account = this.account ?? (throw const ApiException('Please log in again.'));
    if (account.status == AccountStatus.ineligible) {
      throw const ApiException('Warom is only for adults aged 18 and over.', code: ApiException.ineligible);
    }
    if (account.step.isBefore(step)) throw const ApiException('Please complete the previous step first.');
    return account;
  }

  void _advance(Account account, OnboardingStep next) {
    if (account.step.isBefore(next)) account.step = next;
    notifyListeners();
  }

  void _validateAbout(String bio, List<String> interests) {
    if (bio.trim().length < 10) throw const ApiException('Write a bio of at least 10 characters.');
    if (bio.trim().length > 300) throw const ApiException('Keep your bio under 300 characters.');
    if (interests.length < 3 || interests.length > 5) throw const ApiException('Choose 3 to 5 interests.');
  }

  // ---------------------------------------------------------- profile edits

  Future<void> updateProfile(void Function(Profile me) edit) async {
    await _roundTrip();
    final me = _requireMe();
    edit(me);
    _validateProfile(me);
    _discoveryVersion++;
    notifyListeners();
  }

  void _validateProfile(Profile p) {
    if (p.name.trim().isEmpty) throw const ApiException('Please add your name.');
    if (p.age < 18) throw const ApiException('You must be 18 or older to use Warom.');
    if (p.photos.isEmpty) throw const ApiException('Add at least one photo.');
    if (p.minAge < 18 || p.minAge > p.maxAge) throw const ApiException('Check your age range.');
  }

  void _seedIncomingLikes(Profile member) {
    final at = DateTime.now().subtract(const Duration(hours: 3));
    for (final id in seedLikesNewMembers) {
      final seed = _profiles[id]!;
      if (seed.showMe.includes(member.gender)) {
        _interactions.putIfAbsent(_key(id, member.id), () => Interaction(id, member.id, SwipeAction.like, at));
      }
    }
  }

  // -------------------------------------------------------------- discovery

  Future<List<Profile>> discover({int limit = 4, Set<String> skip = const {}}) async {
    await _roundTrip();
    final me = _requireActive();
    final eligible = _profiles.values
        .where((p) => !skip.contains(p.id) && _exclusionReason(me, p) == null)
        .toList()
      ..sort((a, b) => (_rank[a.id] ?? 999).compareTo(_rank[b.id] ?? 999));
    return eligible.take(limit).toList();
  }

  /// Every other member with the rule that keeps them out of Discover, for the pitch screen.
  List<DiscoveryCheck> explainDiscovery() {
    final me = _requireMe();
    final checks = [
      for (final p in _profiles.values)
        if (p.id != me.id) DiscoveryCheck(p, _exclusionReason(me, p)),
    ];
    checks.sort((a, b) {
      if ((a.excludedBecause == null) != (b.excludedBecause == null)) return a.excludedBecause == null ? -1 : 1;
      return (_rank[a.profile.id] ?? 999).compareTo(_rank[b.profile.id] ?? 999);
    });
    return checks;
  }

  String? _exclusionReason(Profile me, Profile p) {
    if (p.id == me.id) return 'This is you';
    if (!p.active) return 'Account inactive or suspended';
    if (!p.discoverable) return 'Hidden from Discover';
    if (!p.meetsVisibilityRequirements) return 'Profile incomplete (needs photo, bio and interests)';
    if (_isBlocked(me.id, p.id)) return 'Blocked';
    if (!me.showMe.includes(p.gender)) return 'Not who you want to meet';
    if (!p.showMe.includes(me.gender)) return 'You\'re not who they want to meet';
    if (p.age < me.minAge || p.age > me.maxAge) return 'Outside your age range';
    if (me.age < p.minAge || me.age > p.maxAge) return 'You\'re outside their age range';
    final km = _distanceKm(me.area, p.area);
    if (km > me.maxDistanceKm) return 'Too far away (${km.round()} km)';
    if (km > p.maxDistanceKm) return 'You\'re outside their distance';
    final mine = _interactions[_key(me.id, p.id)];
    if (mine != null) return mine.action == SwipeAction.like ? 'You already liked them' : 'You already passed';
    if (_matches[_pairId(me.id, p.id)] != null) return 'Already matched';
    return null;
  }

  /// Members only ever see a rounded distance, never coordinates.
  String distanceLabel(Profile other) {
    final km = _distanceKm(_requireMe().area, other.area);
    return km < 1 ? 'Less than 1 km away' : '${km.round()} km away';
  }

  // --------------------------------------------------------------- swiping

  Future<SwipeResult> swipe(String targetId, SwipeAction action) async {
    await _roundTrip();
    final me = _requireActive();
    if (targetId == me.id) throw const ApiException('You can\'t swipe on yourself.');
    final target = _profiles[targetId];
    if (target == null || !target.active || _isBlocked(me.id, targetId)) {
      throw const ApiException('This profile is no longer available.');
    }
    // One interaction per actor and target: a retried request returns the original decision.
    final saved = _interactions.putIfAbsent(
      _key(me.id, targetId),
      () => Interaction(me.id, targetId, action, DateTime.now()),
    );
    final match = saved.action == SwipeAction.like ? _createMatchIfMutual(me, target) : null;
    notifyListeners();
    return SwipeResult(saved.action, match);
  }

  /// Runs as a single database transaction on the real server.
  Match? _createMatchIfMutual(Profile a, Profile b) {
    final reciprocal = _interactions[_key(b.id, a.id)];
    if (reciprocal?.action != SwipeAction.like) return null;
    if (_isBlocked(a.id, b.id) || !a.active || !b.active) return null;
    final ids = [a.id, b.id]..sort();
    final match = _matches.putIfAbsent('${ids[0]}|${ids[1]}', () => Match(ids[0], ids[1], DateTime.now()));
    return match.isActive ? match : null;
  }

  // ------------------------------------------------------- likes & matches

  /// People who liked me and are still waiting for my decision.
  List<Profile> get likesReceived {
    final me = this.me;
    if (me == null) return const [];
    return [
      for (final i in _interactions.values)
        if (i.targetId == me.id &&
            i.action == SwipeAction.like &&
            _profiles[i.actorId]!.active &&
            !_isBlocked(me.id, i.actorId) &&
            !_interactions.containsKey(_key(me.id, i.actorId)))
          _profiles[i.actorId]!,
    ];
  }

  List<MatchSummary> get matches {
    final me = this.me;
    if (me == null) return const [];
    final out = <MatchSummary>[];
    for (final m in _matches.values) {
      if (!m.isActive || !m.includes(me.id)) continue;
      final otherId = m.otherThan(me.id);
      if (_isBlocked(me.id, otherId)) continue;
      final msgs = _messages[m.id] ?? const <Message>[];
      final unread = msgs.where((x) => !x.read && x.senderId != me.id).length;
      out.add(MatchSummary(m, _profiles[otherId]!, msgs.isEmpty ? null : msgs.last, unread));
    }
    out.sort((a, b) => (b.lastMessage?.sentAt ?? b.match.createdAt).compareTo(a.lastMessage?.sentAt ?? a.match.createdAt));
    return out;
  }

  int get unreadTotal => matches.fold(0, (sum, m) => sum + m.unread);

  Profile profile(String id) => _profiles[id]!;

  Match? matchById(String id) => _matches[id];

  // ------------------------------------------------------------------ chat

  List<Message> messages(String matchId) {
    _requireMembership(matchId);
    return List.unmodifiable(_messages[matchId] ?? const <Message>[]);
  }

  bool isTyping(String matchId) => _typing.contains(matchId);

  void markRead(String matchId) {
    final me = _requireMe();
    var changed = false;
    for (final m in _messages[matchId] ?? const <Message>[]) {
      if (!m.read && m.senderId != me.id) {
        m.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> sendMessage(String matchId, String text) async {
    await _roundTrip();
    final me = _requireActive();
    final match = _requireMembership(matchId);
    final otherId = match.otherThan(me.id);
    if (!match.isActive) throw const ApiException('This conversation has ended.');
    if (_isBlocked(me.id, otherId)) throw const ApiException('You can\'t message this person.');
    final body = text.trim();
    if (body.isEmpty) throw const ApiException('Message is empty.');
    if (body.length > maxMessageLength) throw const ApiException('Message is too long.');
    _addMessage(matchId, me.id, body, read: true);
    _scheduleReply(match, otherId);
    notifyListeners();
  }

  void _addMessage(String matchId, String senderId, String text, {bool read = false}) {
    _messages.putIfAbsent(matchId, () => []).add(Message(
          id: 'msg_${++_seq}',
          matchId: matchId,
          senderId: senderId,
          text: text,
          sentAt: DateTime.now(),
          read: read,
        ));
  }

  void _scheduleReply(Match match, String otherId) {
    final script = seedReplies[otherId];
    final cursor = _replyCursor[match.id] ?? 0;
    if (script == null || cursor >= script.length || _typing.contains(match.id)) return;
    _replyCursor[match.id] = cursor + 1;
    _timers.add(Timer(const Duration(milliseconds: 700), () {
      _typing.add(match.id);
      notifyListeners();
      _timers.add(Timer(Duration(milliseconds: 1400 + _random.nextInt(900)), () {
        _typing.remove(match.id);
        if (match.isActive && !_isBlocked(match.userA, match.userB)) _addMessage(match.id, otherId, script[cursor]);
        notifyListeners();
      }));
    }));
  }

  // ---------------------------------------------------------------- safety

  Future<void> unmatch(String matchId) async {
    await _roundTrip();
    _requireMembership(matchId).endedAt = DateTime.now();
    _typing.remove(matchId);
    notifyListeners();
  }

  Future<void> block(String userId) async {
    await _roundTrip();
    final me = _requireMe();
    _blocks.add(_key(me.id, userId));
    _matches[_pairId(me.id, userId)]?.endedAt ??= DateTime.now();
    _discoveryVersion++;
    notifyListeners();
  }

  Future<void> unblock(String userId) async {
    await _roundTrip();
    _blocks.remove(_key(_requireMe().id, userId));
    _discoveryVersion++;
    notifyListeners();
  }

  List<Profile> get blockedProfiles {
    final me = this.me;
    if (me == null) return const [];
    return [
      for (final b in _blocks)
        if (b.startsWith('${me.id}>')) _profiles[b.split('>').last]!,
    ];
  }

  Future<void> report(String userId, String reason) async {
    await _roundTrip();
    _requireMe();
    _reports++;
  }

  // ----------------------------------------------------------------- stats

  Map<String, int> get stats {
    final me = this.me;
    if (me == null) return const {};
    final mine = _interactions.values.where((i) => i.actorId == me.id);
    return {
      'Likes sent': mine.where((i) => i.action == SwipeAction.like).length,
      'Passes': mine.where((i) => i.action == SwipeAction.pass).length,
      'Likes received': _interactions.values.where((i) => i.targetId == me.id && i.action == SwipeAction.like).length,
      'Matches': _matches.values.where((m) => m.includes(me.id)).length,
      'Messages': _messages.values.fold(0, (s, l) => s + l.length),
      'Blocks & reports': _blocks.where((b) => b.startsWith('${me.id}>')).length + _reports,
    };
  }

  // --------------------------------------------------------------- helpers

  Future<void> _roundTrip() async {
    await Future<void>.delayed(_latency);
    if (_simulateNetworkFailure) throw const ApiException('No connection. Please try again.');
  }

  Profile _requireMe() => me ?? (throw const ApiException('Please log in again.'));

  Profile _requireActive() {
    final me = _requireMe();
    if (account?.status != AccountStatus.active) throw const ApiException('Finish setting up your profile first.');
    return me;
  }

  Match _requireMembership(String matchId) {
    final match = _matches[matchId];
    if (match == null || !match.includes(_requireMe().id)) throw const ApiException('Conversation not found.');
    return match;
  }

  bool _isBlocked(String a, String b) => _blocks.contains(_key(a, b)) || _blocks.contains(_key(b, a));

  static String _key(String actor, String target) => '$actor>$target';

  static String _pairId(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  static double _distanceKm(Area a, Area b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }
}
