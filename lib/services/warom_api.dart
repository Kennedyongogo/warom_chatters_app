import '../models/person.dart';
import '../models/social.dart';
import 'warom_client.dart';

class WaromApi {
  WaromApi._();
  static final instance = WaromApi._();
  final _client = WaromClient.instance;

  List<Person> _people(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Person.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Map<String, dynamic> _map(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  Future<Map<String, List<Person>>> homeFeed() async {
    final data = _map(await _client.get('/api/feed/home'));
    return {
      'online': _people(data['online']),
      'offline': _people(data['offline']),
      'trending': _people(data['trending']),
    };
  }

  Future<List<Person>> discover({String? country, String? city}) async {
    final query = <String, String>{};
    if (country != null && country.isNotEmpty) query['country'] = country;
    if (city != null && city.isNotEmpty) query['city'] = city;
    return _people(await _client.get('/api/feed/discover', query: query.isEmpty ? null : query));
  }

  Future<Person> getProfile(String id) async {
    return Person.fromJson(_map(await _client.get('/api/profiles/$id')));
  }

  Future<void> swipe(String targetId, String action) async {
    await _client.post('/api/social/swipe', {'target_id': targetId, 'action': action});
  }

  Future<void> follow(String userId) => _client.post('/api/social/follow/$userId');
  Future<void> unfollow(String userId) => _client.delete('/api/social/follow/$userId');

  Future<Map<String, dynamic>> openChat(String userId) async {
    return _map(await _client.post('/api/chats/open', {'user_id': userId}));
  }

  Future<List<Map<String, dynamic>>> chats() async {
    final data = await _client.get('/api/chats');
    if (data is! List) return const [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final data = await _client.get('/api/chats/$conversationId/messages');
    if (data is! List) return const [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    String conversationId, {
    required String body,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    return _map(
      await _client.post('/api/chats/$conversationId/messages', {
        'body': body,
        'message_type': messageType,
        if (mediaUrl != null) 'media_url': mediaUrl,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> callHistory({String? status}) async {
    final query = status == null ? null : {'status': status};
    final data = await _client.get('/api/calls/history', query: query);
    if (data is! List) return const [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> missedCalls() async {
    final data = await _client.get('/api/calls/missed');
    if (data is! List) return const [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> startCall(String calleeId, String callType) async {
    return _map(
      await _client.post('/api/calls/start', {
        'callee_id': calleeId,
        'call_type': callType,
      }),
    );
  }

  Future<Map<String, dynamic>> updateCall(
    String callId, {
    String? status,
    int? durationSeconds,
    Map<String, dynamic>? signallingPayload,
  }) async {
    return _map(
      await _client.patch('/api/calls/$callId', {
        if (status != null) 'status': status,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (signallingPayload != null) 'signalling_payload': signallingPayload,
      }),
    );
  }

  Future<Map<String, dynamic>> income() async => _map(await _client.get('/api/income'));
  Future<Map<String, dynamic>> incomeTransactions() async =>
      _map(await _client.get('/api/income/transactions'));
  Future<List<dynamic>> incomeHolds() async {
    final data = await _client.get('/api/income/holds');
    return data is List ? data : const [];
  }

  Future<Map<String, dynamic>> requestWithdraw({
    required int amountCoins,
    required String payoutMethod,
    Map<String, dynamic>? payoutDetails,
  }) async {
    return _map(
      await _client.post('/api/income/withdrawals', {
        'amount_coins': amountCoins,
        'payout_method': payoutMethod,
        'payout_details': payoutDetails ?? {},
      }),
    );
  }

  Future<Map<String, dynamic>> wallet() async => _map(await _client.get('/api/wallet'));
  Future<Map<String, dynamic>> catalogue() async => _map(await _client.get('/api/wallet/catalogue'));
  Future<List<dynamic>> walletHistory() async {
    final data = await _client.get('/api/wallet/history');
    return data is List ? data : const [];
  }

  Future<void> buyCoins(String packageId, {bool simulate = true}) async {
    await _client.post('/api/wallet/coins/purchase', {
      'package_id': packageId,
      'simulate_success': simulate,
    });
  }

  Future<void> sendGift({
    required String receiverId,
    required String giftId,
    String? conversationId,
  }) async {
    await _client.post('/api/wallet/gifts/send', {
      'receiver_id': receiverId,
      'gift_id': giftId,
      if (conversationId != null) 'conversation_id': conversationId,
    });
  }

  Future<Map<String, dynamic>> vipMe() async => _map(await _client.get('/api/vip/me'));
  Future<List<dynamic>> vipPlans() async {
    final data = await _client.get('/api/vip/plans');
    return data is List ? data : const [];
  }

  Future<void> subscribeVip(String planId) async {
    await _client.post('/api/vip/subscribe', {'vip_plan_id': planId});
  }

  Future<List<dynamic>> notifications({bool unreadOnly = false}) async {
    final data = await _client.get(
      '/api/notifications',
      query: unreadOnly ? {'unread': 'true'} : null,
    );
    return data is List ? data : const [];
  }

  Future<int> unreadNotifications() async {
    final data = _map(await _client.get('/api/notifications/unread-count'));
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> readNotification(String id) => _client.post('/api/notifications/$id/read');
  Future<void> readAllNotifications() => _client.post('/api/notifications/read-all');

  Future<Map<String, dynamic>> mySocial() async => _map(await _client.get('/api/profiles/me/social'));
  Future<List<Person>> visitors() async {
    final data = await _client.get('/api/profiles/me/visitors');
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) {
          final visitor = e['visitor'];
          if (visitor is Map) return Person.fromJson(Map<String, dynamic>.from(visitor));
          return null;
        })
        .whereType<Person>()
        .toList();
  }

  Future<List<Person>> followers() async => _people(await _client.get('/api/profiles/me/followers'));
  Future<List<Person>> following() async => _people(await _client.get('/api/profiles/me/following'));
  Future<List<Person>> matches() async => _people(await _client.get('/api/profiles/me/matches'));
  Future<List<dynamic>> giftsReceived() async {
    final data = await _client.get('/api/profiles/me/gifts');
    return data is List ? data : const [];
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> patch) async {
    return _map(await _client.patch('/api/profiles/me', patch));
  }

  Future<Map<String, dynamic>> privacy() async => _map(await _client.get('/api/profiles/me/privacy'));
  Future<void> updatePrivacy({String? visibility, Map<String, dynamic>? settings}) async {
    await _client.patch('/api/profiles/me/privacy', {
      if (visibility != null) 'profile_visibility': visibility,
      if (settings != null) 'privacy_settings': settings,
    });
  }

  Future<void> changePassword({required String current, required String next}) async {
    await _client.post('/api/profiles/me/password', {
      'current_password': current,
      'new_password': next,
    });
  }

  Future<void> deleteAccount() => _client.delete('/api/profiles/me');

  /// Upload a local image and return the server URL (`/uploads/...`).
  Future<String> uploadMedia(String localPath, {String kind = 'profile'}) async {
    final data = await _client.uploadFile('/api/media/$kind', localPath);
    final url = '${data['url'] ?? data['absolute_url'] ?? ''}'.trim();
    if (url.isEmpty) throw ApiException('Upload succeeded but no URL was returned.');
    return url;
  }

  Future<List<dynamic>> verifications() async {
    final data = await _client.get('/api/verification/me');
    return data is List ? data : const [];
  }

  Future<void> submitVerification({
    required String kind,
    required List<String> documentUrls,
  }) async {
    await _client.post('/api/verification', {
      'kind': kind,
      'document_urls': documentUrls,
    });
  }

  Future<List<dynamic>> myLockedPhotos() async {
    final data = await _client.get('/api/locked-photos/mine');
    return data is List ? data : const [];
  }

  Future<void> createLockedPhoto({
    required String mediaUrl,
    required int coinPrice,
    String? caption,
  }) async {
    await _client.post('/api/locked-photos', {
      'media_url': mediaUrl,
      'coin_price': coinPrice,
      if (caption != null) 'caption': caption,
    });
  }

  Future<List<dynamic>> liveStreams() async {
    final data = await _client.get('/api/live-streams');
    return data is List ? data : const [];
  }

  Future<Map<String, dynamic>> startLive(String title) async {
    return _map(await _client.post('/api/live-streams', {'title': title}));
  }

  Future<void> endLive(String id) => _client.post('/api/live-streams/$id/end');
}
