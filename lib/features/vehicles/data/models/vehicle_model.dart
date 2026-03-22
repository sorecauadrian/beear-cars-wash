import 'package:cloud_firestore/cloud_firestore.dart';

enum VehicleType {
  small,
  suv,
  busJeep,
  truck;

  static VehicleType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'small':
        return VehicleType.small;
      case 'suv':
        return VehicleType.suv;
      case 'busjeep':
      case 'bus_jeep':
        return VehicleType.busJeep;
      case 'truck':
        return VehicleType.truck;
      default:
        return VehicleType.small;
    }
  }

  @override
  String toString() {
    switch (this) {
      case VehicleType.small:
        return 'small';
      case VehicleType.suv:
        return 'suv';
      case VehicleType.busJeep:
        return 'busJeep';
      case VehicleType.truck:
        return 'truck';
    }
  }

  String get label {
    switch (this) {
      case VehicleType.small:
        return 'Mașină Mică';
      case VehicleType.suv:
        return 'SUV / Family';
      case VehicleType.busJeep:
        return 'Bus / Jeep';
      case VehicleType.truck:
        return 'Camion';
    }
  }
}

/// Vehicle model representing a company vehicle
class VehicleModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final VehicleType vehicleType;
  final String? description;

  VehicleModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    this.vehicleType = VehicleType.small,
    this.description,
  });

  /// Create VehicleModel from Firestore document
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VehicleModel(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      plateNumber: data['plateNumber'] as String? ?? '',
      vehicleType: VehicleType.fromString(data['vehicleType'] as String? ?? 'small'),
      description: data['description'] as String?,
    );
  }

  /// Convert VehicleModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType.toString(),
      if (description != null) 'description': description,
    };
  }

  /// Create VehicleModel from map
  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      plateNumber: map['plateNumber'] as String,
      vehicleType: VehicleType.fromString(map['vehicleType'] as String? ?? 'small'),
      description: map['description'] as String?,
    );
  }

  /// Convert VehicleModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType.toString(),
      'description': description,
    };
  }

  VehicleModel copyWith({
    String? id,
    String? companyId,
    String? plateNumber,
    VehicleType? vehicleType,
    String? description,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      description: description ?? this.description,
    );
  }
}

