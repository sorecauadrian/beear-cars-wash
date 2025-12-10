import 'package:cloud_firestore/cloud_firestore.dart';

/// Client type enum
enum ClientType {
  persoanaFizica, // Individual
  persoanaJuridica; // Legal entity/Company

  static ClientType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'persoana_fizica':
      case 'persoanafizica':
        return ClientType.persoanaFizica;
      case 'persoana_juridica':
      case 'persoanajuridica':
        return ClientType.persoanaJuridica;
      default:
        return ClientType.persoanaFizica;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ClientType.persoanaFizica:
        return 'persoana_fizica';
      case ClientType.persoanaJuridica:
        return 'persoana_juridica';
    }
  }

  String get displayName {
    switch (this) {
      case ClientType.persoanaFizica:
        return 'Persoană Fizică';
      case ClientType.persoanaJuridica:
        return 'Persoană Juridică';
    }
  }
}

/// Company model representing a client (individual or company)
class CompanyModel {
  final String id;
  final String name;
  final ClientType clientType;
  final String email;
  final String password; // Set by admin, stored in plain text (admin manages it)
  final String city;
  final bool isActive;

  CompanyModel({
    required this.id,
    required this.name,
    required this.clientType,
    required this.email,
    required this.password,
    required this.city,
    required this.isActive,
  });

  /// Create CompanyModel from Firestore document
  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      clientType: ClientType.fromString(data['clientType'] as String? ?? 'persoana_fizica'),
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      city: data['city'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert CompanyModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'clientType': clientType.toString(),
      'email': email,
      'password': password,
      'city': city,
      'isActive': isActive,
    };
  }

  /// Create CompanyModel from map
  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      clientType: ClientType.fromString(map['clientType'] as String? ?? 'persoana_fizica'),
      email: map['email'] as String,
      password: map['password'] as String,
      city: map['city'] as String,
      isActive: map['isActive'] as bool,
    );
  }

  /// Convert CompanyModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientType': clientType.toString(),
      'email': email,
      'password': password,
      'city': city,
      'isActive': isActive,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    ClientType? clientType,
    String? email,
    String? password,
    String? city,
    bool? isActive,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientType: clientType ?? this.clientType,
      email: email ?? this.email,
      password: password ?? this.password,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
    );
  }
}

