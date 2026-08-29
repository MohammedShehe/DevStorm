class FamilyMember {
  final String id;
  final String userId;
  final String familyMemberId;
  final String name;
  final String email;
  final String relation;
  final String status; // Pending, Accepted, Rejected

  FamilyMember({
    required this.id,
    required this.userId,
    required this.familyMemberId,
    required this.name,
    required this.email,
    required this.relation,
    required this.status,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final member = json['familyMember'] ?? {};
    return FamilyMember(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      familyMemberId: json['familyMemberId'].toString(),
      name: member['fullName'] ?? '',
      email: member['email'] ?? '',
      relation: json['relation'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'familyMemberId': familyMemberId,
      'relation': relation,
      'status': status,
    };
  }
}