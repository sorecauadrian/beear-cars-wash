import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../bookings/data/models/booking_model.dart';

/// Pricing model for wash types
class PricingModel {
  final String id;
  final double interiorPrice;
  final double exteriorPrice;
  final double tapiteriePrice;
  final double completePrice;
  final DateTime updatedAt;
  final String? updatedBy;

  PricingModel({
    required this.id,
    required this.interiorPrice,
    required this.exteriorPrice,
    required this.tapiteriePrice,
    required this.completePrice,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Get price for a specific wash type
  double getPriceForWashType(WashType washType) {
    switch (washType) {
      case WashType.interior:
        return interiorPrice;
      case WashType.exterior:
        return exteriorPrice;
      case WashType.tapiterie:
        return tapiteriePrice;
      case WashType.all:
        return completePrice;
    }
  }

  /// Create PricingModel from Firestore document
  factory PricingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PricingModel(
      id: doc.id,
      interiorPrice: (data['interiorPrice'] as num?)?.toDouble() ?? 0.0,
      exteriorPrice: (data['exteriorPrice'] as num?)?.toDouble() ?? 0.0,
      tapiteriePrice: (data['tapiteriePrice'] as num?)?.toDouble() ?? 0.0,
      completePrice: (data['completePrice'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  /// Convert PricingModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'interiorPrice': interiorPrice,
      'exteriorPrice': exteriorPrice,
      'tapiteriePrice': tapiteriePrice,
      'completePrice': completePrice,
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  /// Create PricingModel from map
  factory PricingModel.fromMap(Map<String, dynamic> map) {
    return PricingModel(
      id: map['id'] as String,
      interiorPrice: (map['interiorPrice'] as num).toDouble(),
      exteriorPrice: (map['exteriorPrice'] as num).toDouble(),
      tapiteriePrice: (map['tapiteriePrice'] as num).toDouble(),
      completePrice: (map['completePrice'] as num).toDouble(),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  /// Convert PricingModel to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'interiorPrice': interiorPrice,
      'exteriorPrice': exteriorPrice,
      'tapiteriePrice': tapiteriePrice,
      'completePrice': completePrice,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  PricingModel copyWith({
    String? id,
    double? interiorPrice,
    double? exteriorPrice,
    double? tapiteriePrice,
    double? completePrice,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PricingModel(
      id: id ?? this.id,
      interiorPrice: interiorPrice ?? this.interiorPrice,
      exteriorPrice: exteriorPrice ?? this.exteriorPrice,
      tapiteriePrice: tapiteriePrice ?? this.tapiteriePrice,
      completePrice: completePrice ?? this.completePrice,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

