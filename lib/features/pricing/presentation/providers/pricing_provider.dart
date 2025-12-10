import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/pricing_repository.dart';
import '../../data/models/pricing_model.dart';

/// Pricing repository provider
final pricingRepositoryProvider = Provider<PricingRepository>((ref) {
  return PricingRepository();
});

/// Current pricing provider
final currentPricingProvider = StreamProvider<PricingModel?>((ref) {
  final repository = ref.watch(pricingRepositoryProvider);
  return repository.getPricingStream();
});

/// Get current pricing (async)
final getCurrentPricingProvider = FutureProvider<PricingModel?>((ref) {
  final repository = ref.watch(pricingRepositoryProvider);
  return repository.getCurrentPricing();
});

/// Set pricing provider
final setPricingProvider = Provider.family<Future<String>, PricingModel>(
  (ref, pricing) async {
    final repository = ref.read(pricingRepositoryProvider);
    return repository.setPricing(pricing);
  },
);

