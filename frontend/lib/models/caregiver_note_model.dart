class CaregiverNote {
  final String id;
  final String caregiverId;
  final String userId;
  final String note;
  final String caregiverName;
  final String caregiverEmail;
  final DateTime createdAt;

  CaregiverNote({
    required this.id,
    required this.caregiverId,
    required this.userId,
    required this.note,
    required this.caregiverName,
    required this.caregiverEmail,
    required this.createdAt,
  });

  factory CaregiverNote.fromJson(Map<String, dynamic> json) {
    final caregiver = json['caregiver'] ?? {};
    return CaregiverNote(
      id: json['id'].toString(),
      caregiverId: json['caregiverId'].toString(),
      userId: json['userId'].toString(),
      note: json['note'] ?? '',
      caregiverName: caregiver['caregiverName'] ?? '',
      caregiverEmail: caregiver['email'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverId': caregiverId,
      'userId': userId,
      'note': note,
    };
  }
}