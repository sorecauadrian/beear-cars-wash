import 'package:cloud_firestore/cloud_firestore.dart';

/// User role enum
enum UserRole {
  admin,           // BeeAR Admin (service owner)
  companyAdmin,   // Company Admin (client company admin)
  companyWorker;   // Company Worker (Beear employee)

  static UserRole fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'admin':
        return UserRole.admin;
      case 'company_admin':
        return UserRole.companyAdmin;
      case 'company_worker':
        return UserRole.companyWorker;
      default:
        return UserRole.companyAdmin; // Default fallback
    }
  }

  @override
  String toString() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.companyAdmin:
        return 'company_admin';
      case UserRole.companyWorker:
        return 'company_worker';
    }
  }
}

/// User model representing a user in the system
class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? companyId; // Nullable for bee_admin

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.companyId,
  });

  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'company_admin'),
      companyId: data['companyId'] as String?,
    );
  }

  /// Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.toString(),
      if (companyId != null) 'companyId': companyId,
    };
  }

  /// Create UserModel from map (for testing/caching)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.fromString(map['role'] as String),
      companyId: map['companyId'] as String?,
    );
  }

  /// Convert UserModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString(),
      'companyId': companyId,
    };
  }

  /// Check if user is Admin (BeeAR Admin)
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is Company Admin
  bool get isCompanyAdmin => role == UserRole.companyAdmin;

  /// Check if user is Company Worker
  bool get isCompanyWorker => role == UserRole.companyWorker;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? companyId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
    );
  }
}

