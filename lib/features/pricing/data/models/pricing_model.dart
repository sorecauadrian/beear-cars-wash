import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../vehicles/data/models/vehicle_model.dart';

class PricingModel {
  final String id;
  final Map<VehicleType, Map<WashType, double>> prices;
  final double multiVehicleDiscount;
  final DateTime updatedAt;
  final String? updatedBy;

  PricingModel({
    required this.id,
    required this.prices,
    this.multiVehicleDiscount = 10.0,
    required this.updatedAt,
    this.updatedBy,
  });

  double getPrice(VehicleType vehicleType, WashType washType) {
    return prices[vehicleType]?[washType] ?? 0.0;
  }

  factory PricingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PricingModel(
      id: doc.id,
      prices: _parsePrices(data['prices'] as Map<String, dynamic>?),
      multiVehicleDiscount: (data['multiVehicleDiscount'] as num?)?.toDouble() ?? 10.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'prices': _serializePrices(prices),
      'multiVehicleDiscount': multiVehicleDiscount,
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  factory PricingModel.fromMap(Map<String, dynamic> map) {
    return PricingModel(
      id: map['id'] as String,
      prices: _parsePrices(map['prices'] as Map<String, dynamic>?),
      multiVehicleDiscount: (map['multiVehicleDiscount'] as num?)?.toDouble() ?? 10.0,
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prices': _serializePrices(prices),
      'multiVehicleDiscount': multiVehicleDiscount,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  PricingModel copyWith({
    String? id,
    Map<VehicleType, Map<WashType, double>>? prices,
    double? multiVehicleDiscount,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PricingModel(
      id: id ?? this.id,
      prices: prices ?? this.prices,
      multiVehicleDiscount: multiVehicleDiscount ?? this.multiVehicleDiscount,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static Map<VehicleType, Map<WashType, double>> _parsePrices(
    Map<String, dynamic>? data,
  ) {
    final result = <VehicleType, Map<WashType, double>>{};
    if (data == null) return _defaultPrices();

    for (final vehicleType in VehicleType.values) {
      final key = vehicleType.toString();
      final washPrices = data[key] as Map<String, dynamic>?;
      if (washPrices != null) {
        result[vehicleType] = {
          for (final washType in WashType.values)
            washType: (washPrices[washType.toString()] as num?)?.toDouble() ?? 0.0,
        };
      } else {
        result[vehicleType] = {
          for (final washType in WashType.values) washType: 0.0,
        };
      }
    }
    return result;
  }

  static Map<String, dynamic> _serializePrices(
    Map<VehicleType, Map<WashType, double>> prices,
  ) {
    return {
      for (final entry in prices.entries)
        entry.key.toString(): {
          for (final washEntry in entry.value.entries)
            washEntry.key.toString(): washEntry.value,
        },
    };
  }

  static Map<VehicleType, Map<WashType, double>> _defaultPrices() {
    return {
      VehicleType.small: {
        WashType.interior: 40,
        WashType.exterior: 40,
        WashType.all: 75,
      },
      VehicleType.suv: {
        WashType.interior: 45,
        WashType.exterior: 50,
        WashType.all: 90,
      },
      VehicleType.busJeep: {
        WashType.interior: 50,
        WashType.exterior: 60,
        WashType.all: 100,
      },
      VehicleType.truck: {
        WashType.interior: 50,
        WashType.exterior: 100,
        WashType.all: 130,
      },
    };
  }

  static PricingModel defaultPricing() {
    return PricingModel(
      id: '',
      prices: _defaultPrices(),
      multiVehicleDiscount: 10.0,
      updatedAt: DateTime.now(),
    );
  }
}
