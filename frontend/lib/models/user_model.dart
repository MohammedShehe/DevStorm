class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String gender;
  final String? avatarUrl;
  final bool isCaregiverAccount;
  final List<CaregiverLink> linkedCaregivers;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.gender = 'Not specified',
    this.avatarUrl,
    this.isCaregiverAccount = false,
    this.linkedCaregivers = const [],
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCaregiverAccount: isCaregiverAccount,
      linkedCaregivers: linkedCaregivers,
    );
  }
}

class CaregiverLink {
  final String name;
  final String relation;
  final String email;
  final bool accepted;

  CaregiverLink({
    required this.name,
    required this.relation,
    required this.email,
    this.accepted = false,
  });
}
