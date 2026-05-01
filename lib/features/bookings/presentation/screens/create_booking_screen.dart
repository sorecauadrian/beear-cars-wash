import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/error_handler.dart';
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
  final DateTime? initialDate;
  const CreateBookingScreen({super.key, this.initialDate});

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

  // Step 2: Date & Time
  late DateTime _selectedDate;
  final Map<String, String> _vehicleTimeSlots = {}; // vehicleId → slot
  Set<String> _unavailableSlots = {};
  Set<String> _fullDays = {}; // dates formatted as YYYY-MM-DD that have no free slots

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
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadUnavailableSlots();
    _loadFullDays();
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

  Future<void> _loadFullDays() async {
    try {
      final repository = BookingRepository();
      final today = DateTime.now();
      final startStr = DateTimeUtils.formatDate(today);
      final endStr = DateTimeUtils.formatDate(today.add(const Duration(days: 30)));
      final bookings = await repository.getBookingsForDateRange(startStr, endStr);
      final allSlots = DateTimeUtils.getTimeSlots();

      final Map<String, List<BookingModel>> byDate = {};
      for (final b in bookings) {
        if (b.status == BookingStatus.rejected || b.status == BookingStatus.done) continue;
        byDate.putIfAbsent(b.date, () => []).add(b);
      }

      final full = <String>{};
      for (final entry in byDate.entries) {
        final blocked = <String>{};
        for (final b in entry.value) {
          final startIdx = allSlots.indexOf(b.slotStart);
          if (startIdx < 0) { blocked.add(b.slotStart); continue; }
          final endTime = DateTimeUtils.parseTime(b.slotEnd);
          for (int i = startIdx; i < allSlots.length; i++) {
            final slotTime = DateTimeUtils.parseTime(allSlots[i]);
            if (slotTime == null) continue;
            if (endTime != null && !slotTime.isBefore(endTime)) break;
            blocked.add(allSlots[i]);
          }
        }
        if (blocked.length >= allSlots.length) full.add(entry.key);
      }

      if (mounted) setState(() => _fullDays = full);
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
            backgroundColor: Theme.of(context).colorScheme.outline,
            valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
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
    final theme = Theme.of(context);
    final labels = ['Mașini', 'Dată', 'Locație', 'Verifică'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      width: 12,
                      height: 1,
                      color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                  ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone || isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  ),
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
                Icon(Icons.directions_car_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                'Selectează mașinile (max 5)',
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
    final theme = Theme.of(context);
    final typeIcon = _vehicleTypeIcon(vehicle.vehicleType);
    final typeColor = _vehicleTypeColor(vehicle.vehicleType);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (isSelected) {
            _selectedVehicles.removeWhere((v) => v.id == vehicle.id);
            _vehicleWashTypes.remove(vehicle.id);
          } else if (_selectedVehicles.length < 5) {
            _selectedVehicles.add(vehicle);
            _vehicleWashTypes[vehicle.id] = WashType.all;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : typeColor.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusMd,
                    ),
                    child: Icon(
                      typeIcon,
                      color: isSelected ? theme.colorScheme.primary : typeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vehicle.plateNumber,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle.vehicleType.label,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        if (vehicle.description != null && vehicle.description!.isNotEmpty)
                          Text(
                            vehicle.description!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              Divider(height: 1, color: theme.colorScheme.outline),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tip spălare:', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.sm),
                    ...WashType.values.map((type) => _buildWashTypeRow(context, vehicle, type, pricingAsync)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _vehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.small:
        return Icons.directions_car_outlined;
      case VehicleType.suv:
        return Icons.directions_car_filled_outlined;
      case VehicleType.busJeep:
        return Icons.airport_shuttle_outlined;
      case VehicleType.truck:
        return Icons.local_shipping_outlined;
    }
  }

  Color _vehicleTypeColor(VehicleType type) {
    switch (type) {
      case VehicleType.small:
        return AppColors.info;
      case VehicleType.suv:
        return AppColors.secondary;
      case VehicleType.busJeep:
        return AppColors.warning;
      case VehicleType.truck:
        return AppColors.statusInProgress;
    }
  }

  Widget _buildWashTypeRow(BuildContext context, VehicleModel vehicle, WashType type, AsyncValue<dynamic> pricingAsync) {
    final theme = Theme.of(context);
    final isChosen = _vehicleWashTypes[vehicle.id] == type;
    final color = WashTypeUtils.color(type);
    final priceText = pricingAsync.whenOrNull(
      data: (p) => p != null ? '${p.getPrice(vehicle.vehicleType, type).toStringAsFixed(0)} lei' : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isChosen ? color.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
          borderRadius: AppSpacing.borderRadiusMd,
          border: Border.all(
            color: isChosen ? color : theme.colorScheme.outline,
            width: isChosen ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppSpacing.borderRadiusMd,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _vehicleWashTypes[vehicle.id] = type;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChosen ? color : Colors.transparent,
                    border: Border.all(color: isChosen ? color : theme.colorScheme.outline, width: 2),
                  ),
                  child: isChosen
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Icon(WashTypeUtils.icon(type), size: 18, color: isChosen ? color : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    WashTypeUtils.label(type),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isChosen ? FontWeight.w600 : FontWeight.w500,
                      color: isChosen ? color : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (priceText != null)
                  Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isChosen ? color : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
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
    final theme = Theme.of(context);
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
                color: AppColors.info.withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.08),
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 20, color: theme.brightness == Brightness.dark ? AppColors.darkInfo : AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: theme.brightness == Brightness.dark ? AppColors.darkInfo : AppColors.info, height: 1.4),
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
                color: theme.colorScheme.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    DateTimeUtils.formatDateDisplay(_selectedDate),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (_fullDays.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Zilele dezactivate din calendar sunt complet ocupate',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Selectează ora pentru fiecare mașină', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fiecare mașină ocupă un interval de ~${AppConstants.slotDurationMinutes} min',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._selectedVehicles.map((vehicle) => _buildVehicleSlotPicker(context, vehicle)),
          if (_unavailableSlots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: AppSpacing.xs),
                Text('Indisponibil', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: selectedSlot != null ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.colorScheme.outline,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      vehicle.vehicleType.label,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
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
                        ? theme.colorScheme.primary
                        : isOtherVehicle
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : isExternal
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.surface,
                    borderRadius: AppSpacing.borderRadiusMd,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isOtherVehicle
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : theme.colorScheme.outline,
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
                              ? theme.colorScheme.primary.withValues(alpha: 0.5)
                              : isExternal
                                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                  : theme.colorScheme.onSurface,
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
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final lastDay = todayOnly.add(const Duration(days: 30));
    final safeInitial = _selectedDate.isBefore(todayOnly) ? todayOnly : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: todayOnly,
      lastDate: lastDay,
      selectableDayPredicate: (day) {
        final dayStr = DateTimeUtils.formatDate(day);
        return !_fullDays.contains(dayStr);
      },
    );

    if (picked == null) return;

    if (picked.isBefore(todayOnly)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nu poți face o rezervare pentru o dată din trecut'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedDate = picked;
      _vehicleTimeSlots.clear();
    });
    _loadUnavailableSlots();
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
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Map picker card
          InkWell(
            onTap: _openMapPicker,
            borderRadius: AppSpacing.borderRadiusLg,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border.all(
                  color: hasCoords ? theme.colorScheme.primary : theme.colorScheme.outline,
                  width: hasCoords ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: hasCoords
                          ? theme.colorScheme.primary.withValues(alpha: 0.06)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    ),
                    child: hasCoords
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded, size: 36, color: theme.colorScheme.primary),
                              const SizedBox(height: 4),
                              Text(
                                'Locație selectată',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text(
                                'Apasă pentru a selecta pe hartă',
                                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          hasCoords ? Icons.edit_location_alt_outlined : Icons.add_location_alt_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasCoords ? 'Schimbă locația pe hartă' : 'Selectează pe hartă',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.primary),
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
                child: Text('sau introdu manual', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                      child: Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
                color: AppColors.warning.withValues(alpha: theme.brightness == Brightness.dark ? 0.15 : 0.08),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: theme.brightness == Brightness.dark ? AppColors.darkWarning : AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recomandăm selectarea pe hartă pentru localizare precisă.',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.brightness == Brightness.dark ? AppColors.darkWarning : AppColors.warning),
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
              color: theme.colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mașini', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                ..._selectedVehicles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final v = entry.value;
                  final washType = _vehicleWashTypes[v.id] ?? WashType.all;
                  final basePrice = pricingData?.getPrice(v.vehicleType, washType);
                  final hasDiscount = index > 0 && pricingData != null;
                  final discount = hasDiscount ? pricingData.multiVehicleDiscount : 0.0;
                  final finalPrice = basePrice != null ? basePrice - discount : null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.plateNumber, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                              Text(
                                v.vehicleType.label,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          WashTypeUtils.label(washType),
                          style: theme.textTheme.bodySmall?.copyWith(color: WashTypeUtils.color(washType), fontWeight: FontWeight.w600),
                        ),
                        if (finalPrice != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${finalPrice.toStringAsFixed(0)} lei',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (hasDiscount)
                                Text(
                                  '-${discount.toStringAsFixed(0)} lei',
                                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (pricingData != null) ...[
                  const Divider(height: AppSpacing.lg),
                  if (_selectedVehicles.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reducere vehicule suplimentare',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '-${((_selectedVehicles.length - 1) * pricingData.multiVehicleDiscount).toStringAsFixed(0)} lei',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total estimat', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${_calculateTotal(pricingData).toStringAsFixed(0)} lei',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
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
              color: theme.colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dată & Oră', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
                        Icon(Icons.access_time_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${v.plateNumber}: ',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Durată estimată: $_totalEstimatedDuration',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
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
              color: theme.colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusLg,
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locație', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
                      Icon(Icons.note_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
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

  double _calculateTotal(dynamic pricingData) {
    double total = 0;
    for (int i = 0; i < _selectedVehicles.length; i++) {
      final v = _selectedVehicles[i];
      final washType = _vehicleWashTypes[v.id] ?? WashType.all;
      final basePrice = pricingData.getPrice(v.vehicleType, washType) as double;
      final discount = i > 0 ? (pricingData.multiVehicleDiscount as double) : 0.0;
      total += basePrice - discount;
    }
    return total;
  }

  Widget _buildNavigationBar(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, MediaQuery.of(context).padding.bottom + AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5))),
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
          content: Text(AppErrorHandler.userFriendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
