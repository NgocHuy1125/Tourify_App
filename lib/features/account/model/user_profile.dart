class UserProfile {
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

  UserProfile({
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
  });

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
    final birthday = json['birthday'] ?? json['dob'] ?? json['birthdate'];

    return UserProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Nguoi dung',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString(),
      avatarUrl: avatar?.toString(),
      gender: gender?.toString(),
      birthday: parseDate(birthday),
      country: country?.toString(),
      language: language?.toString(),
      currency: currency?.toString(),
    );
  }
}
