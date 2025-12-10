import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pricing_model.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Pricing repository
/// Handles all Firestore operations for pricing
class PricingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current pricing (there should be only one pricing document)
  Future<PricingModel?> getCurrentPricing() async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.pricing)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return PricingModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get pricing: ${e.toString()}');
    }
  }

  /// Get pricing stream
  Stream<PricingModel?> getPricingStream() {
    return _firestore
        .collection(FirestorePaths.pricing)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return PricingModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Create or update pricing
  /// If pricing exists, updates it; otherwise creates new
  Future<String> setPricing(PricingModel pricing) async {
    try {
      // Check if pricing exists
      final existing = await getCurrentPricing();
      
      if (existing != null) {
        // Update existing
        await _firestore
            .collection(FirestorePaths.pricing)
            .doc(existing.id)
            .update(pricing.toFirestore());
        return existing.id;
      } else {
        // Create new
        final docRef = await _firestore
            .collection(FirestorePaths.pricing)
            .add(pricing.toFirestore());
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to set pricing: ${e.toString()}');
    }
  }
}

