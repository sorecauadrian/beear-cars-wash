import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../vehicles/presentation/providers/vehicle_provider.dart';
import '../../../vehicles/data/models/vehicle_model.dart';
import '../../data/models/booking_model.dart';
import '../providers/booking_provider.dart';
import 'package:go_router/go_router.dart';

/// Create booking screen with plate scanner
class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  VehicleModel? _selectedVehicle;
  WashType _selectedWashType = WashType.all;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _isLoading = false;
  bool _showScanner = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleScanPlate() async {
    setState(() {
      _showScanner = true;
    });
  }

  void _handleScanResult(String? plateNumber) {
    if (plateNumber == null || plateNumber.isEmpty) return;

    setState(() {
      _showScanner = false;
    });

    // Find vehicle by plate number
    final vehiclesAsync = ref.read(myVehiclesProvider);
    vehiclesAsync.whenData((vehicles) {
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No vehicles found'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Try to find exact match first
      VehicleModel? vehicle;
      try {
        vehicle = vehicles.firstWhere(
          (v) => v.plateNumber.toUpperCase().replaceAll(' ', '') == 
                 plateNumber.toUpperCase().trim().replaceAll(' ', ''),
        );
      } catch (e) {
        // No exact match found
      }

      if (vehicle != null) {
        setState(() {
          _selectedVehicle = vehicle;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle found: ${vehicle.plateNumber}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle not found: $plateNumber'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vehicle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(
        createBookingProvider(
          CreateBookingParams(
            vehicleId: _selectedVehicle!.id,
            washType: _selectedWashType,
            addressText: _addressController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            date: DateTimeUtils.formatDate(_selectedDate),
            slotStart: _selectedTimeSlot!,
          ),
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Reset time slot when date changes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);

    if (_showScanner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan License Plate'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showScanner = false;
              });
            },
          ),
        ),
        body: MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _handleScanResult(barcode.rawValue);
                break;
              }
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Selection
              vehiclesAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(height: 8),
                            const Text(
                              'No vehicles found',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please add a vehicle first',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Vehicle *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<VehicleModel>(
                        value: _selectedVehicle,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select a vehicle'),
                        items: vehicles.map((vehicle) {
                          return DropdownMenuItem(
                            value: vehicle,
                            child: Text(vehicle.plateNumber),
                          );
                        }).toList(),
                        onChanged: (vehicle) {
                          setState(() {
                            _selectedVehicle = vehicle;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a vehicle';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _handleScanPlate,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan License Plate'),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              ),
              const SizedBox(height: 24),

              // Wash Type Selection
              const Text(
                'Wash Type *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<WashType>(
                segments: const [
                  ButtonSegment(
                    value: WashType.interior,
                    label: Text('Interior'),
                    icon: Icon(Icons.air),
                  ),
                  ButtonSegment(
                    value: WashType.exterior,
                    label: Text('Exterior'),
                    icon: Icon(Icons.water_drop),
                  ),
                  ButtonSegment(
                    value: WashType.cosmetic,
                    label: Text('Cosmetic'),
                    icon: Icon(Icons.auto_awesome),
                  ),
                  ButtonSegment(
                    value: WashType.all,
                    label: Text('All'),
                    icon: Icon(Icons.all_inclusive),
                  ),
                ],
                selected: {_selectedWashType},
                onSelectionChanged: (Set<WashType> newSelection) {
                  setState(() {
                    _selectedWashType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Enter wash location address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Address',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // TODO: Open map picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Map picker coming soon'),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Pick location on map (optional)'),
              ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional notes or special instructions',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Date *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateTimeUtils.formatDateDisplay(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time Slot Selection
              const Text(
                'Time Slot *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estimated duration: ${AppConstants.bookingDurationEstimate}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DateTimeUtils.getTimeSlots().map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  return FilterChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTimeSlot = selected ? slot : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Create Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

