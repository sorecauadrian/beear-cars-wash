import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/models/company_model.dart';

/// Company repository provider
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

/// All companies provider
final allCompaniesProvider = StreamProvider<List<CompanyModel>>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getAllCompaniesStream();
});

/// Company by ID provider
final companyByIdProvider = FutureProvider.family<CompanyModel?, String>(
  (ref, companyId) async {
    final repository = ref.watch(companyRepositoryProvider);
    return repository.getCompanyById(companyId);
  },
);

/// Create company provider
final createCompanyProvider =
    Provider.family<Future<String>, CreateCompanyParams>(
  (ref, params) async {
    final repository = ref.read(companyRepositoryProvider);
    final company = CompanyModel(
      id: '', // Will be set by repository
      name: params.name,
      contractNumber: params.contractNumber,
      city: params.city,
      isActive: params.isActive,
    );
    return repository.createCompany(company);
  },
);

/// Update company provider
final updateCompanyProvider =
    Provider.family<Future<void>, UpdateCompanyParams>(
  (ref, params) async {
    final repository = ref.read(companyRepositoryProvider);
    final company = params.company.copyWith(
      name: params.name,
      contractNumber: params.contractNumber,
      city: params.city,
      isActive: params.isActive,
    );
    return repository.updateCompany(company);
  },
);

/// Delete company provider
final deleteCompanyProvider = Provider.family<Future<void>, String>(
  (ref, companyId) async {
    final repository = ref.read(companyRepositoryProvider);
    return repository.deleteCompany(companyId);
  },
);

/// Create company parameters
class CreateCompanyParams {
  final String name;
  final String contractNumber;
  final String city;
  final bool isActive;

  const CreateCompanyParams({
    required this.name,
    required this.contractNumber,
    required this.city,
    this.isActive = true,
  });
}

/// Update company parameters
class UpdateCompanyParams {
  final CompanyModel company;
  final String name;
  final String contractNumber;
  final String city;
  final bool isActive;

  const UpdateCompanyParams({
    required this.company,
    required this.name,
    required this.contractNumber,
    required this.city,
    required this.isActive,
  });
}


