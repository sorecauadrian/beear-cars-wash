import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Company repository
/// Handles all Firestore operations for companies
class CompanyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all companies
  Future<List<CompanyModel>> getAllCompanies() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.companies)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => CompanyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get companies: ${e.toString()}');
    }
  }

  /// Get companies stream
  Stream<List<CompanyModel>> getAllCompaniesStream() {
    return _firestore
        .collection(FirestorePaths.companies)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompanyModel.fromFirestore(doc))
            .toList());
  }

  /// Get company by ID
  Future<CompanyModel?> getCompanyById(String companyId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.companies)
          .doc(companyId)
          .get();

      if (!doc.exists) return null;
      return CompanyModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get company: ${e.toString()}');
    }
  }

  /// Create a new company
  Future<String> createCompany(CompanyModel company) async {
    try {
      final docRef = await _firestore
          .collection(FirestorePaths.companies)
          .add(company.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create company: ${e.toString()}');
    }
  }

  /// Update company
  Future<void> updateCompany(CompanyModel company) async {
    try {
      await _firestore
          .collection(FirestorePaths.companies)
          .doc(company.id)
          .update(company.toFirestore());
    } catch (e) {
      throw Exception('Failed to update company: ${e.toString()}');
    }
  }

  /// Delete company
  Future<void> deleteCompany(String companyId) async {
    try {
      await _firestore
          .collection(FirestorePaths.companies)
          .doc(companyId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete company: ${e.toString()}');
    }
  }
}

