import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_record_model.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Service record repository
/// Handles all Firestore operations for service records
class ServiceRecordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all service records
  Future<List<ServiceRecordModel>> getAllServiceRecords() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.serviceRecords)
          .orderBy('month', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ServiceRecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get service records: ${e.toString()}');
    }
  }

  /// Get service records stream
  Stream<List<ServiceRecordModel>> getAllServiceRecordsStream() {
    return _firestore
        .collection(FirestorePaths.serviceRecords)
        .orderBy('month', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRecordModel.fromFirestore(doc))
            .toList());
  }

  /// Get service records by company
  Future<List<ServiceRecordModel>> getServiceRecordsByCompany(
      String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.serviceRecords)
          .where('companyId', isEqualTo: companyId)
          .orderBy('month', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ServiceRecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception(
          'Failed to get service records by company: ${e.toString()}');
    }
  }

  /// Get service records by month
  Future<List<ServiceRecordModel>> getServiceRecordsByMonth(
      String month) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.serviceRecords)
          .where('month', isEqualTo: month)
          .orderBy('companyId')
          .get();

      return snapshot.docs
          .map((doc) => ServiceRecordModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception(
          'Failed to get service records by month: ${e.toString()}');
    }
  }

  /// Get service record by company and month (for duplicate checking)
  Future<ServiceRecordModel?> getServiceRecordByCompanyAndMonth(
      String companyId, String month) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.serviceRecords)
          .where('companyId', isEqualTo: companyId)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ServiceRecordModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception(
          'Failed to get service record by company and month: ${e.toString()}');
    }
  }

  /// Get service record by ID
  Future<ServiceRecordModel?> getServiceRecordById(String recordId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.serviceRecords)
          .doc(recordId)
          .get();

      if (!doc.exists) return null;
      return ServiceRecordModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get service record: ${e.toString()}');
    }
  }

  /// Create a new service record
  Future<String> createServiceRecord(ServiceRecordModel record) async {
    try {
      // Check for duplicate
      final existing = await getServiceRecordByCompanyAndMonth(
          record.companyId, record.month);
      if (existing != null) {
        throw Exception(
            'Un înregistrare pentru această companie și lună există deja.');
      }

      final docRef = await _firestore
          .collection(FirestorePaths.serviceRecords)
          .add(record.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create service record: ${e.toString()}');
    }
  }

  /// Update service record
  Future<void> updateServiceRecord(ServiceRecordModel record) async {
    try {
      if (record.isFinalized) {
        throw Exception('Nu poți edita o înregistrare finalizată.');
      }

      await _firestore
          .collection(FirestorePaths.serviceRecords)
          .doc(record.id)
          .update(record.toFirestore());
    } catch (e) {
      throw Exception('Failed to update service record: ${e.toString()}');
    }
  }

  /// Delete service record
  Future<void> deleteServiceRecord(String recordId) async {
    try {
      final record = await getServiceRecordById(recordId);
      if (record?.isFinalized == true) {
        throw Exception('Nu poți șterge o înregistrare finalizată.');
      }

      await _firestore
          .collection(FirestorePaths.serviceRecords)
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete service record: ${e.toString()}');
    }
  }
}

