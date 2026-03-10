import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
import '../../../../shared/utils/wash_type_utils.dart';
import 'package:go_router/go_router.dart';

class CreateBookingScreen extends ConsumerStatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  ConsumerState<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  final _totalSteps = 4;

  // Step 1: Vehicles
  final List<VehicleModel> _selectedVehicles = [];
  final Map<String, WashType> _vehicleWashTypes = {};
  final Map<String, WashType?> _expandedWashType = {};

  // Step 2: Date & Time
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _vehicleTimeSlots = {}; // vehicleId → slot
  Set<String> _unavailableSlots = {};

  // Step 3: Location
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  double? _selectedLat;
  double? _selectedLng;

  // State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnavailableSlots();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUnavailableSlots() async {
    try {
      final repository = BookingRepository();
      final dateString = DateTimeUtils.formatDate(_selectedDate);
      final bookings = await repository.getAllBookings(date: dateString);
      final allSlots = DateTimeUtils.getTimeSlots();
      final blocked = <String>{};

      for (final b in bookings) {
        if (b.status == BookingStatus.rejected || b.status == BookingStatus.done) continue;

        // Mark every slot from slotStart up to (but not including) slotEnd
        final startIdx = allSlots.indexOf(b.slotStart);
        if (startIdx < 0) {
          blocked.add(b.slotStart);
          continue;
        }

        final endTime = DateTimeUtils.parseTime(b.slotEnd);
        for (int i = startIdx; i < allSlots.length; i++) {
          final slotTime = DateTimeUtils.parseTime(allSlots[i]);
          if (slotTime == null) continue;
          if (endTime != null && !slotTime.isBefore(endTime)) break;
          blocked.add(allSlots[i]);
        }
      }

      setState(() => _unavailableSlots = blocked);
    } catch (_) {}
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedVehicles.isNotEmpty && _selectedVehicles.every((v) => _vehicleWashTypes.containsKey(v.id));
      case 1:
        return _selectedVehicles.every((v) => _vehicleTimeSlots.containsKey(v.id));
      case 2:
        return _addressController.text.trim().isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervare nouă'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: AppColors.outline,
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(context),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Vehicles(context),
                _buildStep2DateTime(context),
                _buildStep3Location(context),
                _buildStep4Review(context),
              ],
            ),
          ),
          // Navigation
          _buildNavigationBar(context),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final labels = ['Mașini', 'Dată & Oră', 'Locație', 'Confirmare'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.accent : isActive ? AppColors.accent : AppColors.outline,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < labels.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(width: 8, height: 1, color: AppColors.outline),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══ Step 1: Vehicle Selection ═══
  Widget _buildStep1Vehicles(BuildContext context) {
    final vehiclesAsync = ref.watch(myVehiclesProvider);
    final pricingAsync = ref.watch(pricing.currentPricingProvider);

    return vehiclesAsync.when(
      data: (vehicles) {
        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 56, color: AppColors.onSurfaceVariant),
                const SizedBox(height: AppSpacing.md),
                Text('Adaugă o mașină mai întâi', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selectează mașinile (max 3)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              ...vehicles.map((vehicle) {
                final isSelected = _selectedVehicles.any((v) => v.id == vehicle.id);
                return _buildVehicleCard(context, vehicle, isSelected, pricingAsync);
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Eroare: $e')),
    );
  }

  Widget _buildVehicleCard(BuildContext context, VehicleModel vehicle, bool isSelected, AsyncValue<dynamic> pricingAsync) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedVehicles.removeWhere((v) => v.id == vehicle.id);
            _vehicleWashTypes.remove(vehicle.id);
          } else if (_selectedVehicles.length < 3) {
            _selectedVehicles.add(vehicle);
            _vehicleWashTypes[vehicle.id] = WashType.all;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLight : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  color: isSelected ? AppColors.accent : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.plateNumber,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (vehicle.description != null && vehicle.description!.isNotEmpty)
                        Text(
                          vehicle.description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(color: isSelected ? AppColors.accent : AppColors.outline, width: 2),
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Tip spălare:', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.sm),
              ...WashType.values.map((type) => _buildWashTypeRow(context, vehicle, type, pricingAsync)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWashTypeRow(BuildContext context, VehicleModel vehicle, WashType type, AsyncValue<dynamic> pricingAsync) {
    final isChosen = _vehicleWashTypes[vehicle.id] == type;
    final isExpanded = _expandedWashType[vehicle.id] == type;
    final color = WashTypeUtils.color(type);
    final priceText = pricingAsync.whenOrNull(
      data: (p) => p != null ? '${p.getPriceForWashType(type).toStringAsFixed(0)} lei' : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isChosen ? color.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isChosen ? color : AppColors.outline,
            width: isChosen ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: AppSpacing.borderRadiusMd,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _vehicleWashTypes[vehicle.id] = type;
                  _expandedWashType[vehicle.id] =
                      _expandedWashType[vehicle.id] == type ? null : type;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isChosen ? color : Colors.transparent,
                        border: Border.all(color: isChosen ? color : AppColors.outline, width: 2),
                      ),
                      child: isChosen
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Icon(WashTypeUtils.icon(type), size: 18, color: isChosen ? color : AppColors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        WashTypeUtils.label(type),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isChosen ? FontWeight.w600 : FontWeight.w500,
                          color: isChosen ? color : AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (priceText != null)
                      Text(
                        priceText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isChosen ? color : AppColors.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, size: 20, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildWashTypeDetails(context, type, pricingAsync),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWashTypeDetails(BuildContext context, WashType type, AsyncValue<dynamic> pricingAsync) {
    final color = WashTypeUtils.color(type);
    final details = WashTypeUtils.details(type);
    final durationLabel = WashTypeUtils.estimatedDurationLabel(type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: color.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 10),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                'Durată estimată: $durationLabel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══ Step 2: Date & Time ═══

  String get _totalEstimatedDuration {
    if (_selectedVehicles.isEmpty) return '';
    int totalMinutes = 0;
    for (final v in _selectedVehicles) {
      final wt = _vehicleWashTypes[v.id] ?? WashType.all;
      totalMinutes += WashTypeUtils.estimatedMinutes(wt);
    }
    if (totalMinutes >= 60) {
      final h = totalMinutes ~/ 60;
      final m = totalMinutes % 60;
      return m > 0 ? '~${h}h ${m}min' : '~${h}h';
    }
    return '~$totalMinutes min';
  }

  Widget _buildStep2DateTime(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration estimate banner
          if (_selectedVehicles.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 20, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.info, height: 1.4),
                        children: [
                          const TextSpan(text: 'Durată estimată pentru '),
                          TextSpan(
                            text: '${_selectedVehicles.length} ${_selectedVehicles.length == 1 ? 'mașină' : 'mașini'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ': '),
                          TextSpan(
                            text: _totalEstimatedDuration,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text('Selectează data', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: _selectDate,
            borderRadius: AppSpacing.borderRadiusMd,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    DateTimeUtils.formatDateDisplay(_selectedDate),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Selectează ora pentru fiecare mașină', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fiecare mașină ocupă un interval de ~${AppConstants.slotDurationMinutes} min',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._selectedVehicles.map((vehicle) => _buildVehicleSlotPicker(context, vehicle)),
          if (_unavailableSlots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: AppSpacing.xs),
                Text('Indisponibil', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Set<String> _slotsUsedByOtherVehicles(String currentVehicleId) {
    final used = <String>{};
    _vehicleTimeSlots.forEach((vId, slot) {
      if (vId != currentVehicleId) used.add(slot);
    });
    return used;
  }

  Widget _buildVehicleSlotPicker(BuildContext context, VehicleModel vehicle) {
    final theme = Theme.of(context);
    final slots = DateTimeUtils.getTimeSlots();
    final selectedSlot = _vehicleTimeSlots[vehicle.id];
    final washType = _vehicleWashTypes[vehicle.id] ?? WashType.all;
    final otherUsed = _slotsUsedByOtherVehicles(vehicle.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: selectedSlot != null ? AppColors.accent.withValues(alpha: 0.4) : AppColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 18, color: WashTypeUtils.color(washType)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  vehicle.plateNumber,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: WashTypeUtils.color(washType).withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  WashTypeUtils.label(washType),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: WashTypeUtils.color(washType),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selectedSlot != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: slots.map((slot) {
              final isSelected = selectedSlot == slot;
              final isExternal = _unavailableSlots.contains(slot);
              final isOtherVehicle = otherUsed.contains(slot);
              final isUnavailable = isExternal || isOtherVehicle;

              return GestureDetector(
                onTap: isUnavailable
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _vehicleTimeSlots.remove(vehicle.id);
                          } else {
                            _vehicleTimeSlots[vehicle.id] = slot;
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : isOtherVehicle
                            ? AppColors.accent.withValues(alpha: 0.08)
                            : isExternal
                                ? AppColors.surfaceVariant
                                : AppColors.surface,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : isOtherVehicle
                              ? AppColors.accent.withValues(alpha: 0.3)
                              : AppColors.outline,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : isOtherVehicle
                              ? AppColors.accent.withValues(alpha: 0.5)
                              : isExternal
                                  ? AppColors.onSurfaceVariant.withValues(alpha: 0.5)
                                  : AppColors.onSurface,
                      decoration: isExternal ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
        _vehicleTimeSlots.clear();
      });
      _loadUnavailableSlots();
    }
  }

  // ═══ Step 3: Location ═══

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context, rootNavigator: true).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => MapPicker(
        initialLat: _selectedLat,
        initialLng: _selectedLng,
        initialAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
      )),
    );
    if (result != null && mounted) {
      setState(() {
        final address = result['address'] as String? ?? '';
        if (address.isNotEmpty && address != 'Se încarcă adresa...') {
          _addressController.text = address;
        }
        _selectedLat = result['lat'] as double?;
        _selectedLng = result['lng'] as double?;
      });
    }
  }

  /// Attempts to geocode the manually typed address into coordinates so
  /// the admin can reliably open it in Google Maps later.
  Future<void> _geocodeTypedAddress() async {
    if (_selectedLat != null && _selectedLng != null) return;
    final text = _addressController.text.trim();
    if (text.isEmpty) return;
    try {
      final locations = await locationFromAddress(text);
      if (locations.isNotEmpty && mounted) {
        setState(() {
          _selectedLat = locations.first.latitude;
          _selectedLng = locations.first.longitude;
        });
      }
    } catch (_) {
      // Geocoding failed — coordinates will remain null.
      // MapUtils.openDirections will fall back to the text address.
    }
  }

  Widget _buildStep3Location(BuildContext context) {
    final theme = Theme.of(context);
    final hasCoords = _selectedLat != null && _selectedLng != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Locația spălării', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Selectează locația pe hartă sau introdu adresa manual',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Map picker card
          InkWell(
            onTap: _openMapPicker,
            borderRadius: AppSpacing.borderRadiusLg,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                  color: hasCoords ? AppColors.accent : AppColors.outline,
                  width: hasCoords ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Map preview area
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: hasCoords
                          ? AppColors.accent.withValues(alpha: 0.06)
                          : AppColors.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: hasCoords
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded, size: 36, color: AppColors.accent),
                              const SizedBox(height: 4),
                              Text(
                                'Locație selectată',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}',
                                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 36, color: AppColors.onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text(
                                'Apasă pentru a selecta pe hartă',
                                style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                  ),
                  // Button row
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          hasCoords ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined,
                          size: 20,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasCoords ? 'Schimbă locația pe hartă' : 'Selectează pe hartă',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, size: 20, color: AppColors.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Divider with "sau"
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('sau introdu manual', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Manual address input
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Adresă',
              hintText: 'Ex: Str. Libertății nr. 10, Bistrița',
              prefixIcon: const Icon(Icons.edit_location_outlined),
              suffixIcon: _addressController.text.isNotEmpty && !hasCoords
                  ? Tooltip(
                      message: 'Adresa va fi geocodată automat',
                      child: Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceVariant),
                    )
                  : null,
            ),
            maxLines: 2,
            onChanged: (_) {
              // Clear coordinates when user edits the address manually
              // so we know we need to geocode it
              if (_selectedLat != null || _selectedLng != null) {
                _selectedLat = null;
                _selectedLng = null;
              }
              setState(() {});
            },
          ),

          if (_addressController.text.isNotEmpty && !hasCoords) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recomandăm selectarea pe hartă pentru localizare precisă.',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Notes section
          Text('Note (opțional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Instrucțiuni speciale sau detalii...',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ═══ Step 4: Review ═══
  Widget _buildStep4Review(BuildContext context) {
    final theme = Theme.of(context);
    final pricingAsync = ref.watch(pricing.currentPricingProvider);
    final pricingData = pricingAsync.whenOrNull(data: (p) => p);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verifică rezervarea', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),

          // Vehicles summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mașini', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                ..._selectedVehicles.map((v) {
                  final washType = _vehicleWashTypes[v.id] ?? WashType.all;
                  final price = pricingData?.getPriceForWashType(washType);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car_outlined, size: 18, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(v.plateNumber, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        ),
                        Text(
                          WashTypeUtils.label(washType),
                          style: theme.textTheme.bodySmall?.copyWith(color: WashTypeUtils.color(washType), fontWeight: FontWeight.w600),
                        ),
                        if (price != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${price.toStringAsFixed(0)} lei',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (pricingData != null) ...[
                  const Divider(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total estimat', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${_selectedVehicles.fold<double>(0, (sum, v) => sum + (pricingData.getPriceForWashType(_vehicleWashTypes[v.id] ?? WashType.all))).toStringAsFixed(0)} lei',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.accent),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date & Time summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dată & Oră', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text(DateTimeUtils.formatDateDisplay(_selectedDate), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ..._selectedVehicles.map((v) {
                  final slot = _vehicleTimeSlots[v.id];
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 18, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${v.plateNumber}: ',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          slot ?? '-',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Durată estimată: $_totalEstimatedDuration',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Location summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locație', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _addressController.text.isNotEmpty ? _addressController.text : '-',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                if (_descriptionController.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.note_outlined, size: 18, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(_descriptionController.text, style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, MediaQuery.of(context).padding.bottom + AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => _goToStep(_currentStep - 1),
              child: const Text('Înapoi'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _canProceed
                ? () {
                    if (isLastStep) {
                      _handleSave();
                    } else {
                      _goToStep(_currentStep + 1);
                    }
                  }
                : null,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : Text(isLastStep ? 'Confirmă rezervarea' : 'Continuă'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // If user typed an address manually without using the map,
      // try to geocode it so the admin gets proper coordinates
      await _geocodeTypedAddress();

      final repository = ref.read(bookingRepositoryProvider);
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.whenOrNull(data: (u) => u);

      if (user == null || user.companyId == null) {
        throw Exception('Utilizatorul nu a fost găsit');
      }

      final now = DateTime.now();
      final dateString = DateTimeUtils.formatDate(_selectedDate);

      for (final vehicle in _selectedVehicles) {
        final washType = _vehicleWashTypes[vehicle.id]!;
        final vehicleSlot = _vehicleTimeSlots[vehicle.id]!;
        final startTime = DateTimeUtils.parseTime(vehicleSlot);
        final minutes = WashTypeUtils.estimatedMinutes(washType);
        final slotEnd = startTime != null
            ? DateTimeUtils.formatTime(startTime.add(Duration(minutes: minutes)))
            : DateTimeUtils.getEndSlot(vehicleSlot);

        final booking = BookingModel(
          id: '',
          companyId: user.companyId!,
          vehicleId: vehicle.id,
          washType: washType,
          addressText: _addressController.text.trim(),
          lat: _selectedLat,
          lng: _selectedLng,
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          date: dateString,
          slotStart: vehicleSlot,
          slotEnd: slotEnd,
          status: BookingStatus.requested,
          createdAt: now,
          updatedAt: now,
        );

        final bookingId = await repository.createBooking(booking);

        final notificationService = NotificationSenderService();
        final bookingWithId = booking.copyWith(id: bookingId);
        await notificationService.sendNewBookingNotificationToAdmin(booking: bookingWithId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedVehicles.length} rezervări create cu succes'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
