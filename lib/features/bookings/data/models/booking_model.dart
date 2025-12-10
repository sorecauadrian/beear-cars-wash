import 'package:cloud_firestore/cloud_firestore.dart';

/// Wash type enum
enum WashType {
  interior,
  exterior,
  tapiterie,
  all;

  static WashType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'interior':
        return WashType.interior;
      case 'exterior':
        return WashType.exterior;
      case 'tapiterie':
      case 'cosmetic': // Legacy support
        return WashType.tapiterie;
      case 'all':
        return WashType.all;
      default:
        return WashType.all;
    }
  }

  @override
  String toString() {
    switch (this) {
      case WashType.interior:
        return 'interior';
      case WashType.exterior:
        return 'exterior';
      case WashType.tapiterie:
        return 'tapiterie';
      case WashType.all:
        return 'all';
    }
  }
}

/// Booking status enum
enum BookingStatus {
  requested,
  accepted,
  rejected,
  cancelled, // Admin-initiated cancellation (accident, can't make it, etc.)
  inProgress,
  done;

  static BookingStatus fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'requested':
        return BookingStatus.requested;
      case 'accepted':
        return BookingStatus.accepted;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'done':
        return BookingStatus.done;
      default:
        return BookingStatus.requested;
    }
  }

  @override
  String toString() {
    switch (this) {
      case BookingStatus.requested:
        return 'requested';
      case BookingStatus.accepted:
        return 'accepted';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.done:
        return 'done';
    }
  }
}

/// Booking model representing a car wash booking
class BookingModel {
  final String id;
  final String companyId;
  final String vehicleId;
  final WashType washType;
  final String addressText;
  final double? lat;
  final double? lng;
  final String? description; // Optional booking description/notes
  final String date; // YYYY-MM-DD format
  final String slotStart; // HH:mm format
  final String slotEnd; // HH:mm format
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.companyId,
    required this.vehicleId,
    required this.washType,
    required this.addressText,
    this.lat,
    this.lng,
    this.description,
    required this.date,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create BookingModel from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      vehicleId: data['vehicleId'] as String? ?? '',
      washType: WashType.fromString(data['washType'] as String? ?? 'all'),
      addressText: data['addressText'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      description: data['description'] as String?,
      date: data['date'] as String? ?? '',
      slotStart: data['slotStart'] as String? ?? '',
      slotEnd: data['slotEnd'] as String? ?? '',
      status: BookingStatus.fromString(data['status'] as String? ?? 'requested'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert BookingModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'vehicleId': vehicleId,
      'washType': washType.toString(),
      'addressText': addressText,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (description != null) 'description': description,
      'date': date,
      'slotStart': slotStart,
      'slotEnd': slotEnd,
      'status': status.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create BookingModel from map
  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      vehicleId: map['vehicleId'] as String,
      washType: WashType.fromString(map['washType'] as String),
      addressText: map['addressText'] as String,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      description: map['description'] as String?,
      date: map['date'] as String,
      slotStart: map['slotStart'] as String,
      slotEnd: map['slotEnd'] as String,
      status: BookingStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert BookingModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'vehicleId': vehicleId,
      'washType': washType.toString(),
      'addressText': addressText,
      'lat': lat,
      'lng': lng,
      'description': description,
      'date': date,
      'slotStart': slotStart,
      'slotEnd': slotEnd,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? companyId,
    String? vehicleId,
    WashType? washType,
    String? addressText,
    double? lat,
    double? lng,
    String? description,
    String? date,
    String? slotStart,
    String? slotEnd,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      vehicleId: vehicleId ?? this.vehicleId,
      washType: washType ?? this.washType,
      addressText: addressText ?? this.addressText,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      date: date ?? this.date,
      slotStart: slotStart ?? this.slotStart,
      slotEnd: slotEnd ?? this.slotEnd,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

