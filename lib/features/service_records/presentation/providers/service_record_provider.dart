import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/service_record_repository.dart';
import '../../data/models/service_record_model.dart';

/// Service record repository provider
final serviceRecordRepositoryProvider =
    Provider<ServiceRecordRepository>((ref) {
  return ServiceRecordRepository();
});

/// All service records provider
final allServiceRecordsProvider =
    StreamProvider<List<ServiceRecordModel>>((ref) {
  final repository = ref.watch(serviceRecordRepositoryProvider);
  return repository.getAllServiceRecordsStream();
});

/// Service records by company provider
final serviceRecordsByCompanyProvider =
    StreamProvider.family<List<ServiceRecordModel>, String>((ref, companyId) {
  final repository = ref.watch(serviceRecordRepositoryProvider);
  return repository
      .getAllServiceRecordsStream()
      .map((records) => records.where((r) => r.companyId == companyId).toList());
});

/// Service records by month provider
final serviceRecordsByMonthProvider =
    StreamProvider.family<List<ServiceRecordModel>, String>((ref, month) {
  final repository = ref.watch(serviceRecordRepositoryProvider);
  return repository
      .getAllServiceRecordsStream()
      .map((records) => records.where((r) => r.month == month).toList());
});

