import 'package:cloud_firestore/cloud_firestore.dart';

/// Service record model representing monthly service records for companies
class ServiceRecordModel {
  final String id;
  final String companyId;
  final String month; // Format: "YYYY-MM" (e.g., "2024-01")
  final int interiorWashes;
  final int exteriorWashes;
  final int completeWashes;
  final String? notes;
  final bool isFinalized;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRecordModel({
    required this.id,
    required this.companyId,
    required this.month,
    required this.interiorWashes,
    required this.exteriorWashes,
    required this.completeWashes,
    this.notes,
    this.isFinalized = false,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalServices =>
      interiorWashes + exteriorWashes + completeWashes;

  factory ServiceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceRecordModel(
      id: doc.id,
      companyId: data['companyId'] as String? ?? '',
      month: data['month'] as String? ?? '',
      interiorWashes: (data['interiorWashes'] as num?)?.toInt() ?? 0,
      exteriorWashes: (data['exteriorWashes'] as num?)?.toInt() ?? 0,
      completeWashes: (data['completeWashes'] as num?)?.toInt() ?? 0,
      notes: data['notes'] as String?,
      isFinalized: data['isFinalized'] as bool? ?? false,
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'month': month,
      'interiorWashes': interiorWashes,
      'exteriorWashes': exteriorWashes,
      'completeWashes': completeWashes,
      if (notes != null) 'notes': notes,
      'isFinalized': isFinalized,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ServiceRecordModel.fromMap(Map<String, dynamic> map) {
    return ServiceRecordModel(
      id: map['id'] as String,
      companyId: map['companyId'] as String,
      month: map['month'] as String,
      interiorWashes: (map['interiorWashes'] as num?)?.toInt() ?? 0,
      exteriorWashes: (map['exteriorWashes'] as num?)?.toInt() ?? 0,
      completeWashes: (map['completeWashes'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String?,
      isFinalized: map['isFinalized'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'month': month,
      'interiorWashes': interiorWashes,
      'exteriorWashes': exteriorWashes,
      'completeWashes': completeWashes,
      'notes': notes,
      'isFinalized': isFinalized,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ServiceRecordModel copyWith({
    String? id,
    String? companyId,
    String? month,
    int? interiorWashes,
    int? exteriorWashes,
    int? completeWashes,
    String? notes,
    bool? isFinalized,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceRecordModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      month: month ?? this.month,
      interiorWashes: interiorWashes ?? this.interiorWashes,
      exteriorWashes: exteriorWashes ?? this.exteriorWashes,
      completeWashes: completeWashes ?? this.completeWashes,
      notes: notes ?? this.notes,
      isFinalized: isFinalized ?? this.isFinalized,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
