class Caregiver {
  final String id;
  final String name;
  final String email;
  final String status; // Pending, Accepted, Rejected

  Caregiver({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    return Caregiver(
      id: json['id'].toString(),
      name: json['caregiverName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverName': name,
      'email': email,
      'status': status,
    };
  }
}