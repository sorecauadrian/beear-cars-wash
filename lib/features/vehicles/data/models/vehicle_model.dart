import 'package:cloud_firestore/cloud_firestore.dart';

/// Vehicle model representing a company vehicle
class VehicleModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final String? description;

  VehicleModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    this.description,
  });

  /// Create VehicleModel from Firestore document
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      plateNumber: data['plateNumber'] as String? ?? '',
      description: data['description'] as String?,
    );
  }

  /// Convert VehicleModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'plateNumber': plateNumber,
      if (description != null) 'description': description,
    };
  }

  /// Create VehicleModel from map
  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      plateNumber: map['plateNumber'] as String,
      description: map['description'] as String?,
    );
  }

  /// Convert VehicleModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'plateNumber': plateNumber,
      'description': description,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? companyId,
    String? plateNumber,
    String? description,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      plateNumber: plateNumber ?? this.plateNumber,
      description: description ?? this.description,
    );
  }
}

