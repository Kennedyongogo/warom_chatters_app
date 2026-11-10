import 'profile.dart';

enum SwipeAction { like, pass }

class Interaction {
  final String actorId;
  final String targetId;
  final SwipeAction action;
  final DateTime createdAt;

  const Interaction(this.actorId, this.targetId, this.action, this.createdAt);
}

class Match {
  /// Lower id first, so a pair can only ever produce one match.
  final String userA;
  final String userB;
  final DateTime createdAt;
  DateTime? endedAt;

  Match(this.userA, this.userB, this.createdAt);

  String get id => '$userA|$userB';
  bool get isActive => endedAt == null;
  bool includes(String userId) => userA == userId || userB == userId;
  String otherThan(String userId) => userA == userId ? userB : userA;
}

class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  bool read;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.read = false,
  });
}

class SwipeResult {
  final SwipeAction action;
  final Match? match;

  const SwipeResult(this.action, this.match);

  bool get matched => match != null;
}

class MatchSummary {
  final Match match;
  final Profile other;
  final Message? lastMessage;
  final int unread;

  const MatchSummary(this.match, this.other, this.lastMessage, this.unread);

  bool get isNew => lastMessage == null;
}

class DiscoveryCheck {
  final Profile profile;

  /// Null when the profile is eligible to be shown.
  final String? excludedBecause;

  const DiscoveryCheck(this.profile, this.excludedBecause);
}

class ApiException implements Exception {
  static const ineligible = 'ineligible';
  static const noAccount = 'no_account';

  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => message;
}
