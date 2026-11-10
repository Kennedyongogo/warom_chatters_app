import 'dart:io';

import 'package:flutter/widgets.dart';

enum Gender {
  woman('Woman'),
  man('Man');

  const Gender(this.label);
  final String label;
}

enum ShowMe {
  women('Women'),
  men('Men'),
  everyone('Everyone');

  const ShowMe(this.label);
  final String label;

  bool includes(Gender gender) => switch (this) {
        ShowMe.women => gender == Gender.woman,
        ShowMe.men => gender == Gender.man,
        ShowMe.everyone => true,
      };
}

class Area {
  final String name;
  final double lat;
  final double lng;

  const Area(this.name, this.lat, this.lng);

  static const all = [
    Area('Westlands, Nairobi', -1.2676, 36.8108),
    Area('Kilimani, Nairobi', -1.2921, 36.7856),
    Area('Kileleshwa, Nairobi', -1.2808, 36.7836),
    Area('Lavington, Nairobi', -1.2766, 36.7680),
    Area('Karen, Nairobi', -1.3197, 36.7073),
    Area('South B, Nairobi', -1.3108, 36.8379),
    Area('Langata, Nairobi', -1.3610, 36.7460),
    Area('Kasarani, Nairobi', -1.2219, 36.8973),
    Area('Embakasi, Nairobi', -1.3236, 36.8947),
    Area('Ruaka, Kiambu', -1.2050, 36.7870),
    Area('Thika', -1.0333, 37.0693),
    Area('Nakuru', -0.3031, 36.0800),
    Area('Mombasa', -4.0435, 39.6682),
  ];

  static Area named(String name) => all.firstWhere((a) => a.name == name);
}

class Profile {
  final String id;
  String name;
  DateTime birthDate;
  Gender gender;
  ShowMe showMe;
  String bio;
  String? work;
  List<String> interests;
  List<String> photos;
  Area area;
  int minAge;
  int maxAge;
  int maxDistanceKm;
  bool discoverable;
  bool active;

  Profile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.showMe,
    this.bio = '',
    this.work,
    List<String>? interests,
    List<String>? photos,
    required this.area,
    this.minAge = 18,
    this.maxAge = 40,
    this.maxDistanceKm = 30,
    this.discoverable = true,
    this.active = true,
  })  : interests = interests ?? [],
        photos = photos ?? [];

  int get age {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) years--;
    return years;
  }

  String get firstName => name.split(' ').first;

  bool get meetsVisibilityRequirements => photos.isNotEmpty && bio.trim().isNotEmpty && interests.isNotEmpty;
}

/// Profile photos are either bundled sample assets or files the user picked from their gallery.
ImageProvider photoProvider(String path) =>
    path.startsWith('assets/') ? AssetImage(path) as ImageProvider : FileImage(File(path));
