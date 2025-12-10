import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/map_picker.dart';
import '../../../../core/services/notification_sender_service.dart';
import '../../../vehicles/presentation/providers/vehicle_provider.dart';
import '../../../vehicles/data/models/vehicle_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../pricing/presentation/providers/pricing_provider.dart' as pricing;
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../providers/booking_provider.dart';
import 'package:go_router/go_router.dart';

/// Create booking screen - supports up to 3 vehicles
class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final List<VehicleModel> _selectedVehicles = [];
  final Map<String, WashType> _vehicleWashTypes = {}; // vehicleId -> washType
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _isLoading = false;
  double? _selectedLat;
  double? _selectedLng;
  Set<String> _unavailableSlots = {};

  @override
  void initState() {
    super.initState();
    _loadUnavailableSlots();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUnavailableSlots() async {
    
    try {
      final repository = BookingRepository();
      final dateString = DateTimeUtils.formatDate(_selectedDate);
      final bookings = await repository.getAllBookings(date: dateString);
      
      setState(() {
        _unavailableSlots = bookings
            .where((b) => b.status != BookingStatus.rejected && 
                         b.status != BookingStatus.done)
            .map((b) => b.slotStart)
            .toSet();
      });
    } catch (e) {
      // Ignore errors, just don't show unavailable slots
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează cel puțin o mașină'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează un interval orar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all vehicles have wash types
    for (final vehicle in _selectedVehicles) {
      if (!_vehicleWashTypes.containsKey(vehicle.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selectează tipul de spălare pentru ${vehicle.plateNumber}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final userAsync = ref.read(currentUserProvider);
      
      final user = userAsync.when(
        data: (u) => u,
        loading: () => throw Exception('Se încarcă datele utilizatorului'),
        error: (e, _) => throw Exception('Eroare utilizator: $e'),
      );

      if (user == null || user.companyId == null) {
        throw Exception('Utilizatorul nu a fost găsit sau nu are companie asociată');
      }

      final now = DateTime.now();
      final dateString = DateTimeUtils.formatDate(_selectedDate);
      final slotEnd = DateTimeUtils.getEndSlot(_selectedTimeSlot!);

      // Create a booking for each vehicle
      for (final vehicle in _selectedVehicles) {
        final washType = _vehicleWashTypes[vehicle.id]!;
        final booking = BookingModel(
          id: '',
          companyId: user.companyId!,
          vehicleId: vehicle.id,
          washType: washType,
          addressText: _addressController.text.trim(),
          lat: _selectedLat,
          lng: _selectedLng,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          date: dateString,
          slotStart: _selectedTimeSlot!,
          slotEnd: slotEnd,
          status: BookingStatus.accepted,
          createdAt: now,
          updatedAt: now,
        );

        final bookingId = await repository.createBooking(booking);
        
        // Send notification to admin about new booking
        final notificationService = NotificationSenderService();
        final bookingWithId = BookingModel(
          id: bookingId,
          companyId: booking.companyId,
          vehicleId: booking.vehicleId,
          washType: booking.washType,
          addressText: booking.addressText,
          lat: booking.lat,
          lng: booking.lng,
          description: booking.description,
          date: booking.date,
          slotStart: booking.slotStart,
          slotEnd: booking.slotEnd,
          status: booking.status,
          createdAt: booking.createdAt,
          updatedAt: booking.updatedAt,
        );
        await notificationService.sendNewBookingNotificationToAdmin(
          booking: bookingWithId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedVehicles.length} rezervări create cu succes'),
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
        _selectedTimeSlot = null;
      });
      _loadUnavailableSlots();
    }
  }

  void _addVehicle(VehicleModel vehicle) {
    if (_selectedVehicles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poți selecta maximum 3 mașini'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedVehicles.any((v) => v.id == vehicle.id)) {
      return; // Already selected
    }

    setState(() {
      _selectedVehicles.add(vehicle);
      _vehicleWashTypes[vehicle.id] = WashType.all; // Default
    });
  }

  void _removeVehicle(VehicleModel vehicle) {
    setState(() {
      _selectedVehicles.removeWhere((v) => v.id == vehicle.id);
      _vehicleWashTypes.remove(vehicle.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    final pricingAsync = ref.watch(pricing.currentPricingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creează rezervare'),
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
                              'Nu există mașini',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Adaugă o mașină mai întâi',
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
                      Row(
                        children: [
                          const Text(
                            'Mașini *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_selectedVehicles.length}/3',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<VehicleModel>(
                        key: ValueKey('vehicle_dropdown_${_selectedVehicles.length}'),
                        value: null, // Always null - we add vehicles separately
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                          hintText: 'Selectează o mașină',
                        ),
                        items: vehicles
                            .where((v) => !_selectedVehicles.any((sv) => sv.id == v.id))
                            .map((vehicle) {
                          return DropdownMenuItem(
                            value: vehicle,
                            child: Text(vehicle.plateNumber),
                          );
                        }).toList(),
                        onChanged: (vehicle) {
                          if (vehicle != null) {
                            _addVehicle(vehicle);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // Selected vehicles
                      ..._selectedVehicles.map((vehicle) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        vehicle.plateNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () => _removeVehicle(vehicle),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tip spălare:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                pricingAsync.when(
                                  data: (pricing) => Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.interior,
                                        'Interior',
                                        Icons.air,
                                        Colors.blue,
                                        pricing?.interiorPrice ?? 0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.exterior,
                                        'Exterior',
                                        Icons.water_drop,
                                        Colors.cyan,
                                        pricing?.exteriorPrice ?? 0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.tapiterie,
                                        'Tapițerie',
                                        Icons.chair,
                                        Colors.orange,
                                        pricing?.tapiteriePrice ?? 0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.all,
                                        'Completă',
                                        Icons.all_inclusive,
                                        Colors.purple,
                                        pricing?.completePrice ?? 0.0,
                                      ),
                                    ],
                                  ),
                                  loading: () => Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.interior,
                                        'Interior',
                                        Icons.air,
                                        Colors.blue,
                                        0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.exterior,
                                        'Exterior',
                                        Icons.water_drop,
                                        Colors.cyan,
                                        0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.tapiterie,
                                        'Tapițerie',
                                        Icons.chair,
                                        Colors.orange,
                                        0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.all,
                                        'Completă',
                                        Icons.all_inclusive,
                                        Colors.purple,
                                        0.0,
                                      ),
                                    ],
                                  ),
                                  error: (_, __) => Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.interior,
                                        'Interior',
                                        Icons.air,
                                        Colors.blue,
                                        0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.exterior,
                                        'Exterior',
                                        Icons.water_drop,
                                        Colors.cyan,
                                        0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.tapiterie,
                                        'Tapițerie',
                                        Icons.chair,
                                        Colors.orange,
                                        0.0,
                                      ),
                                      _buildWashTypeChip(
                                        vehicle.id,
                                        WashType.all,
                                        'Completă',
                                        Icons.all_inclusive,
                                        Colors.purple,
                                        0.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('Eroare: $error'),
              ),
              const SizedBox(height: 24),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresă *',
                  hintText: 'Introdu adresa locației de spălare',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) => Validators.required(
                  value,
                  fieldName: 'Adresă',
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapPicker(),
                          ),
                        );
                        if (result != null && mounted) {
                          setState(() {
                            _addressController.text = result['address'] ?? '';
                            _selectedLat = result['lat'] as double?;
                            _selectedLng = result['lng'] as double?;
                          });
                        }
                      },
                icon: const Icon(Icons.map),
                label: const Text('Selectează locația pe hartă'),
              ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descriere (Opțional)',
                  hintText: 'Note suplimentare sau instrucțiuni speciale',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),

              // Date Selection
              const Text(
                'Dată *',
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
                'Interval orar *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DateTimeUtils.getTimeSlots().map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  final isUnavailable = _unavailableSlots.contains(slot);
                  
                  return Container(
                    decoration: isSelected && !isUnavailable
                        ? BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          )
                        : null,
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUnavailable) 
                            const Icon(Icons.block, size: 16, color: Colors.white)
                          else if (isSelected)
                            const Icon(Icons.check_circle, size: 16, color: Colors.white),
                          if ((isUnavailable || isSelected) && !isUnavailable) 
                            const SizedBox(width: 6),
                          Text(
                            slot,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? Colors.white 
                                  : isUnavailable 
                                      ? Colors.grey[600]
                                      : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected && !isUnavailable,
                      onSelected: isUnavailable
                          ? null
                          : (selected) {
                              setState(() {
                                _selectedTimeSlot = selected ? slot : null;
                              });
                            },
                      selectedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: isUnavailable
                          ? Colors.grey[300]
                          : Colors.grey[200],
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: isSelected ? 4 : 0,
                    ),
                  );
                }).toList(),
              ),
              if (_unavailableSlots.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.block, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Intervale indisponibile',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
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
                    : const Text('Creează rezervare'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWashTypeChip(
    String vehicleId,
    WashType washType,
    String label,
    IconData icon,
    Color color,
    double price,
  ) {
    final isSelected = _vehicleWashTypes[vehicleId] == washType;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Text(
                price > 0 ? '${price.toStringAsFixed(2)} RON' : 'Preț necunoscut',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _vehicleWashTypes[vehicleId] = washType;
          });
        }
      },
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}

