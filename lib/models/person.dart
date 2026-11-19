import '../config.dart';

/// Lightweight person card from WAROM profile payloads.
class Person {
  final String id;
  final String username;
  final String? email;
  final String? bio;
  final String? country;
  final String? city;
  final String? gender;
  final String? profilePicture;
  final List<String> photos;
  final List<String> coverPhotos;
  final List<dynamic> hobbies;
  final bool isOnline;
  final bool isVip;
  final bool isVerified;
  final String accountType;

  const Person({
    required this.id,
    required this.username,
    this.email,
    this.bio,
    this.country,
    this.city,
    this.gender,
    this.profilePicture,
    this.photos = const [],
    this.coverPhotos = const [],
    this.hobbies = const [],
    this.isOnline = false,
    this.isVip = false,
    this.isVerified = false,
    this.accountType = 'user',
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic value) {
      if (value is! List) return const [];
      return value.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    }

    return Person(
      id: '${json['id']}',
      username: '${json['username'] ?? json['name'] ?? 'Member'}',
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      gender: json['gender'] as String?,
      profilePicture: json['profile_picture'] as String?,
      photos: list(json['photos']),
      coverPhotos: list(json['cover_photos']),
      hobbies: json['hobbies'] is List ? json['hobbies'] as List : const [],
      isOnline: json['is_online'] == true,
      isVip: json['is_vip'] == true,
      isVerified: json['is_verified'] == true,
      accountType: '${json['account_type'] ?? 'user'}',
    );
  }

  String get displayName => username;
  String get locationLabel {
    final parts = [city, country].whereType<String>().where((e) => e.trim().isNotEmpty);
    return parts.isEmpty ? 'Worldwide' : parts.join(', ');
  }

  String? get avatarUrl {
    final raw = profilePicture ?? (photos.isNotEmpty ? photos.first : null);
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    if (raw.startsWith('/')) return '$kWaromApiBase$raw';
    return '$kWaromApiBase/$raw';
  }
}
