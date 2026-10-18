import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kazzi_credit/core/storage/key_value_store.dart';
import 'package:kazzi_credit/features/auth/application/auth_controller.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';

@immutable
class Profile {
  const Profile({
    required this.name,
    required this.memberSince,
    this.mobile = '',
    this.email = '',
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String,
    mobile: j['mobile'] as String? ?? '',
    email: j['email'] as String? ?? '',
    memberSince: DateTime.parse(j['memberSince'] as String),
  );

  const Profile.empty(this.memberSince) : name = '', mobile = '', email = '';

  final String name;

  /// Ten digits after +63, e.g. 9171234567.
  final String mobile;
  final String email;
  final DateTime memberSince;

  bool get isEmpty => name.trim().isEmpty;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  /// +63 917 123 4567
  String get mobileDisplay => mobile.length == 10
      ? '+63 ${mobile.substring(0, 3)} ${mobile.substring(3, 6)} '
            '${mobile.substring(6)}'
      : mobile;

  Profile copyWith({String? name, String? mobile, String? email}) => Profile(
    name: name ?? this.name,
    mobile: mobile ?? this.mobile,
    email: email ?? this.email,
    memberSince: memberSince,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'mobile': mobile,
    'email': email,
    'memberSince': memberSince.toIso8601String(),
  };
}

/// Loaded in `main()`; null before onboarding.
final initialProfileProvider = Provider<Profile?>((ref) => null);

class ProfileController extends Notifier<Profile> {
  static const _key = 'profile.v1';

  @override
  Profile build() {
    ref.listen(authControllerProvider.select((a) => a.onboarded), (
      wasOnboarded,
      onboarded,
    ) {
      if ((wasOnboarded ?? false) && !onboarded) {
        state = Profile.empty(ref.read(clockProvider)());
      }
    });
    return ref.watch(initialProfileProvider) ??
        Profile.empty(ref.watch(clockProvider)());
  }

  void save(Profile profile) {
    final renamed = profile.name.trim() != state.name.trim();
    state = profile;
    unawaited(
      ref.read(keyValueStoreProvider).write(_key, jsonEncode(state.toJson())),
    );
    // Cards print the holder's name; keep the demo cards in sync.
    if (renamed && profile.name.trim().isNotEmpty) {
      ref.read(cardsProvider.notifier).renameHolder(profile.name.trim());
    }
  }

  static Future<Profile?> load(KeyValueStore store) async {
    final raw = await store.read(_key);
    if (raw == null) return null;
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

final profileProvider = NotifierProvider<ProfileController, Profile>(
  ProfileController.new,
);
