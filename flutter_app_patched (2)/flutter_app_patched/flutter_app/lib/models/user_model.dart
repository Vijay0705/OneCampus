class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String rollNumber;
  final String department;
  final int year;
  final String? phone;
  final String createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.rollNumber,
    required this.department,
    required this.year,
    this.phone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      rollNumber: json['rollNumber'] ?? json['studentId'] ?? '',
      department: json['department'] ?? json['dept'] ?? '',
      year: (json['year'] is int)
          ? json['year']
          : int.tryParse(json['year']?.toString() ?? '1') ?? 1,
      phone: json['phone'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isStudent => role == 'student';
  bool get canPostAnnouncement => role == 'admin' || role == 'staff';
  bool get canManageCanteen => role == 'admin' || role == 'canteen_staff' || role == 'staff';
}