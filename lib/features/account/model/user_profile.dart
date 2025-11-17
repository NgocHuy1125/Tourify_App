class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.avatarUrl,
    this.gender,
    this.birthday,
    this.country,
    this.language,
    this.currency,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.address,
    this.googleAccount,
    this.facebookAccount,
    this.notificationPreferences = const {},
    this.extraLoginMethods = const {},
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? avatarUrl;
  final String? gender;
  final DateTime? birthday;
  final String? country;
  final String? language;
  final String? currency;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? address;
  final String? googleAccount;
  final String? facebookAccount;
  final Map<String, bool> notificationPreferences;
  final Map<String, String> extraLoginMethods;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final raw = value.toString();
      if (raw.isEmpty) return null;
      try {
        return DateTime.parse(raw);
      } catch (_) {
        return null;
      }
    }

    Map<String, String> parseLoginMethods(dynamic raw) {
      final result = <String, String>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value == null) return;
          final trimmed = value.toString().trim();
          if (trimmed.isEmpty) return;
          final lowerKey = key.toString().toLowerCase();
          if (lowerKey == 'primary' ||
              lowerKey == 'current' ||
              lowerKey == 'default') {
            result[lowerKey] = trimmed;
          } else {
            result[lowerKey] = trimmed;
          }
        });
      } else if (raw is Iterable) {
        for (final item in raw) {
          if (item is Map) {
            final provider =
                item['provider'] ?? item['type'] ?? item['channel'];
            final identifier =
                item['value'] ?? item['identifier'] ?? item['email'];
            if (provider == null || identifier == null) continue;
            final trimmed = identifier.toString().trim();
            if (trimmed.isEmpty) continue;
            result[provider.toString().toLowerCase()] = trimmed;
          }
        }
      }
      return result;
    }

    Map<String, bool> parseNotificationPrefs(dynamic raw) {
      final result = <String, bool>{};
      if (raw is Map) {
        raw.forEach((key, value) {
          if (value is bool) {
            result[key.toString()] = value;
          } else if (value is num) {
            result[key.toString()] = value != 0;
          } else if (value is String) {
            final lower = value.toLowerCase();
            result[key.toString()] =
                lower == 'true' || lower == '1' || lower == 'on';
          }
        });
      }
      return result;
    }

    String? stringOrNull(dynamic value) {
      if (value == null) return null;
      final trimmed = value.toString().trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final rawName =
        json['name'] ?? json['full_name'] ?? json['display_name'] ?? '';
    final name =
        rawName.toString().trim().isEmpty ? 'Người dùng' : rawName.toString();

    final avatar =
        json['avatar_url'] ??
        json['avatar'] ??
        json['photo'] ??
        json['image'] ??
        json['profile_picture'] ??
        json['picture'];

    final gender = json['gender'] ?? json['sex'] ?? json['salutation'];
    final country =
        json['country'] ??
        json['country_name'] ??
        json['country_code'] ??
        json['nationality'];
    final language = json['language'] ?? json['preferred_language'];
    final currency = json['currency'] ?? json['preferred_currency'];
    final addressLine1 =
        stringOrNull(json['address_line1'] ?? json['addressLine1']);
    final addressLine2 =
        stringOrNull(json['address_line2'] ?? json['addressLine2']);
    final city = stringOrNull(json['city'] ?? json['city_name']);
    final state = stringOrNull(json['state'] ?? json['province']);
    final postalCode =
        stringOrNull(json['postal_code'] ?? json['zip'] ?? json['zipcode']);
    final addressCandidates = [
      stringOrNull(json['address']),
      stringOrNull(json['address_full']),
      stringOrNull(json['full_address']),
      stringOrNull(json['contact_address']),
    ];
    final resolvedAddress =
        addressCandidates.firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        ) ??
        [
          addressLine1,
          addressLine2,
          city,
          state,
          postalCode,
          country?.toString(),
        ]
            .whereType<String>()
            .map((e) => e.trim())
            .where((value) => value.isNotEmpty)
            .join(', ');
    final rawBirthday = json['birthday'] ?? json['dob'] ?? json['birthdate'];

    final baseLoginMethods = parseLoginMethods(
      json['login_methods'] ??
          json['linked_accounts'] ??
          json['auth_providers'],
    );

    final primaryLogin =
        json['primary_login'] ??
        json['primary_login_method'] ??
        json['default_login_method'];
    if (primaryLogin != null) {
      baseLoginMethods['primary'] = primaryLogin.toString().toLowerCase();
    }
    final currentLogin = json['current_login_method'];
    if (currentLogin != null) {
      baseLoginMethods['current'] = currentLogin.toString().toLowerCase();
    }

    final notificationPrefs = parseNotificationPrefs(
      json['notification_preferences'] ?? json['notifications'],
    );

    final email = json['email']?.toString() ?? '';
    final phone = stringOrNull(json['phone']);
    final googleAccount = stringOrNull(
      json['google_account'] ?? json['google'],
    );
    final facebookAccount = stringOrNull(
      json['facebook_account'] ?? json['facebook'],
    );

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: name,
      email: email,
      phone: phone,
      role: json['role']?.toString(),
      avatarUrl: avatar?.toString(),
      gender: gender?.toString(),
      birthday: parseDate(rawBirthday),
      country: country?.toString(),
      language: language?.toString(),
      currency: currency?.toString(),
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      postalCode: postalCode,
      address: resolvedAddress.isEmpty ? null : resolvedAddress,
      googleAccount: googleAccount,
      facebookAccount: facebookAccount,
      notificationPreferences: notificationPrefs,
      extraLoginMethods: baseLoginMethods,
    );
  }

  List<LoginMethod> get loginMethods {
    final methods = <LoginMethod>[];

    void addMethod(String provider, String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      methods.add(LoginMethod(provider: provider, value: trimmed));
    }

    addMethod('email', email);
    addMethod('phone', phone);
    addMethod('google', googleAccount);
    addMethod('facebook', facebookAccount);

    extraLoginMethods.forEach((provider, identifier) {
      if (provider == 'primary' ||
          provider == 'current' ||
          provider == 'default') {
        return;
      }
      addMethod(provider, identifier);
    });

    final seen = <String>{};
    final deduplicated = <LoginMethod>[];
    for (final method in methods) {
      final key = '${method.provider}:${method.value}';
      if (seen.add(key)) {
        deduplicated.add(method);
      }
    }
    return deduplicated;
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthday,
    String? country,
    String? language,
    String? currency,
    String? avatarUrl,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? address,
    String? googleAccount,
    String? facebookAccount,
    Map<String, bool>? notificationPreferences,
    Map<String, String>? extraLoginMethods,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      country: country ?? this.country,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      address: address ?? this.address,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      googleAccount: googleAccount ?? this.googleAccount,
      facebookAccount: facebookAccount ?? this.facebookAccount,
      notificationPreferences:
          notificationPreferences ??
          Map<String, bool>.from(this.notificationPreferences),
      extraLoginMethods:
          extraLoginMethods ?? Map<String, String>.from(this.extraLoginMethods),
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'gender': gender,
      'birthday': birthday?.toIso8601String(),
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'address': address,
      'google_account': googleAccount,
      'facebook_account': facebookAccount,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class LoginMethod {
  const LoginMethod({
    required this.provider,
    required this.value,
    this.verified = true,
  });

  final String provider;
  final String value;
  final bool verified;

  String providerLabel() {
    switch (provider.toLowerCase()) {
      case 'email':
        return 'Email';
      case 'phone':
        return 'Số điện thoại';
      case 'google':
        return 'Google';
      case 'facebook':
        return 'Facebook';
      default:
        return provider;
    }
  }
}
