// User roles in the system
enum UserRole { distributor, salesman }

// User model for authentication and profile
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      role: map['role'] == 'distributor'
          ? UserRole.distributor
          : UserRole.salesman,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role == UserRole.distributor ? 'distributor' : 'salesman',
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  bool get isDistributor => role == UserRole.distributor;
  bool get isSalesman => role == UserRole.salesman;
}
