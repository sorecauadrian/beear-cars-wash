import 'package:cloud_firestore/cloud_firestore.dart';

/// Company model representing a client company
class CompanyModel {
  final String id;
  final String name;
  final String contractNumber;
  final String city;
  final bool isActive;

  CompanyModel({
    required this.id,
    required this.name,
    required this.contractNumber,
    required this.city,
    required this.isActive,
  });

  /// Create CompanyModel from Firestore document
  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      contractNumber: data['contractNumber'] as String? ?? '',
      city: data['city'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Convert CompanyModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'contractNumber': contractNumber,
      'city': city,
      'isActive': isActive,
    };
  }

  /// Create CompanyModel from map
  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      contractNumber: map['contractNumber'] as String,
      city: map['city'] as String,
      isActive: map['isActive'] as bool,
    );
  }

  /// Convert CompanyModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contractNumber': contractNumber,
      'city': city,
      'isActive': isActive,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? contractNumber,
    String? city,
    bool? isActive,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contractNumber: contractNumber ?? this.contractNumber,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
    );
  }
}

