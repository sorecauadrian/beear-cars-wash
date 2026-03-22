import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/companies/data/repositories/company_repository.dart';
import '../../../../features/companies/data/models/company_model.dart';
import '../../data/models/service_record_model.dart';
import '../../data/repositories/service_record_repository.dart';
import '../providers/service_record_provider.dart';
import 'package:go_router/go_router.dart';

/// Add/Edit service record screen
class AddEditServiceRecordScreen extends ConsumerStatefulWidget {
  final String? recordId;

  const AddEditServiceRecordScreen({
    super.key,
    this.recordId,
  });

  @override
  ConsumerState<AddEditServiceRecordScreen> createState() =>
      _AddEditServiceRecordScreenState();
}

class _AddEditServiceRecordScreenState
    extends ConsumerState<AddEditServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String? _selectedCompanyId;
  DateTime? _selectedMonth;
  int _interiorWashes = 0;
  int _exteriorWashes = 0;
  int _completeWashes = 0;
  bool _isFinalized = false;
  bool _isLoading = false;
  bool _isEditing = false;
  ServiceRecordModel? _existingRecord;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recordId != null;
    if (_isEditing) {
      _loadRecord();
    } else {
      // Default to current month
      final now = DateTime.now();
      _selectedMonth = DateTime(now.year, now.month);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    if (widget.recordId == null) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(serviceRecordRepositoryProvider);
      final record = await repository.getServiceRecordById(widget.recordId!);
      
      if (record != null && mounted) {
        setState(() {
          _existingRecord = record;
          _selectedCompanyId = record.companyId;
          _selectedMonth = _parseMonth(record.month);
          _interiorWashes = record.interiorWashes;
          _exteriorWashes = record.exteriorWashes;
          _completeWashes = record.completeWashes;
          _isFinalized = record.isFinalized;
          _notesController.text = record.notes ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcare: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  DateTime _parseMonth(String month) {
    final parts = month.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  String _formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCompanyId == null || _selectedMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează compania și luna'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_interiorWashes == 0 &&
        _exteriorWashes == 0 &&
        _completeWashes == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adaugă cel puțin un serviciu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(serviceRecordRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final firebaseUser = authRepo.currentUser;
      final now = DateTime.now();

      final record = ServiceRecordModel(
        id: _isEditing ? widget.recordId! : '',
        companyId: _selectedCompanyId!,
        month: _formatMonth(_selectedMonth!),
        interiorWashes: _interiorWashes,
        exteriorWashes: _exteriorWashes,
        completeWashes: _completeWashes,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isFinalized: _isFinalized,
        createdBy: firebaseUser?.uid,
        createdAt: _isEditing ? _existingRecord!.createdAt : now,
        updatedAt: now,
      );

      if (_isEditing) {
        await repository.updateServiceRecord(record);
      } else {
        await repository.createServiceRecord(record);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Înregistrarea a fost actualizată'
              : 'Înregistrarea a fost creată'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDelete() async {
    if (widget.recordId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Șterge înregistrarea'),
        content: const Text(
          'Ești sigur că vrei să ștergi această înregistrare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(serviceRecordRepositoryProvider);
      await repository.deleteServiceRecord(widget.recordId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Înregistrarea a fost ștearsă'),
          backgroundColor: AppColors.success,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = FutureProvider<List<CompanyModel>>((ref) async {
      final repository = CompanyRepository();
      return repository.getAllCompanies();
    });
    final companies = ref.watch(companiesAsync);

    if (_isLoading && _isEditing && _existingRecord == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editare înregistrare'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isReadOnly = _isFinalized && _isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editează înregistrare' : 'Adaugă înregistrare'),
        actions: _isEditing && !isReadOnly
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: _handleDelete,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Company selector
              companies.when(
                data: (companiesList) => DropdownButtonFormField<String>(
                  value: _selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Companie *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: companiesList.map((company) {
                    return DropdownMenuItem<String>(
                      value: company.id,
                      child: Text(company.name),
                    );
                  }).toList(),
                  onChanged: isReadOnly
                      ? null
                      : (value) => setState(() => _selectedCompanyId = value),
                  validator: (value) =>
                      value == null ? 'Selectează o companie' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Eroare la încărcarea companiilor'),
              ),
              const SizedBox(height: 16),

              // Month picker
              InkWell(
                onTap: isReadOnly
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedMonth ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          helpText: 'Selectează luna',
                          initialDatePickerMode: DatePickerMode.year,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedMonth = DateTime(picked.year, picked.month);
                          });
                        }
                      },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Lună *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedMonth != null
                        ? DateFormat('MMMM yyyy', 'ro_RO').format(_selectedMonth!)
                        : 'Selectează luna',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Service counts section
              Text(
                'Număr servicii',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              _buildServiceCounter(
                'Interior',
                _interiorWashes,
                AppColors.secondary,
                Icons.air,
                isReadOnly,
              ),
              const SizedBox(height: 12),
              _buildServiceCounter(
                'Exterior',
                _exteriorWashes,
                AppColors.primary,
                Icons.water_drop,
                isReadOnly,
              ),
              const SizedBox(height: 12),
              _buildServiceCounter(
                'Interior + Exterior',
                _completeWashes,
                AppColors.accent,
                Icons.all_inclusive,
                isReadOnly,
              ),
              const SizedBox(height: 24),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total servicii',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${_interiorWashes + _exteriorWashes + _completeWashes}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Note (opțional)',
                  hintText: 'Note despre serviciile din această lună...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 4,
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 24),

              // Finalize toggle
              if (_isEditing && !isReadOnly)
                Card(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  child: SwitchListTile(
                    title: const Text('Finalizează înregistrarea'),
                    subtitle: const Text(
                      'Odată finalizată, înregistrarea nu mai poate fi editată',
                    ),
                    value: _isFinalized,
                    onChanged: (value) {
                      if (value) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Finalizează înregistrarea'),
                            content: const Text(
                              'Ești sigur că vrei să finalizezi această înregistrare? '
                              'Odată finalizată, nu vei mai putea să o editezi.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Anulează'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() => _isFinalized = true);
                                },
                                child: const Text('Finalizează'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        setState(() => _isFinalized = false);
                      }
                    },
                  ),
                ),
              if (isReadOnly)
                Card(
                  color: AppColors.done.withValues(alpha: 0.1),
                  child: const ListTile(
                    leading: Icon(Icons.lock, color: AppColors.done),
                    title: Text('Înregistrare finalizată'),
                    subtitle: Text('Această înregistrare nu mai poate fi editată'),
                  ),
                ),
              const SizedBox(height: 32),

              // Save button
              if (!isReadOnly)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Salvează modificările' : 'Creează înregistrare'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCounter(
    String label,
    int value,
    Color color,
    IconData icon,
    bool isReadOnly,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isReadOnly) ...[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > 0
                    ? () => setState(() {
                          switch (label) {
                            case 'Interior':
                              _interiorWashes--;
                              break;
                            case 'Exterior':
                              _exteriorWashes--;
                              break;
                            case 'Interior + Exterior':
                              _completeWashes--;
                              break;
                          }
                        })
                    : null,
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() {
                  switch (label) {
                    case 'Interior':
                      _interiorWashes++;
                      break;
                    case 'Exterior':
                      _exteriorWashes++;
                      break;
                    case 'Interior + Exterior':
                      _completeWashes++;
                      break;
                  }
                }),
              ),
            ] else
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

