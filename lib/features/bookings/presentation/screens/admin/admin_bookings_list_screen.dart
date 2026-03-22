import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/utils/map_utils.dart';
import '../../../../../core/utils/date_time_utils.dart';
import '../../../../../core/services/notification_sender_service.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../../features/companies/data/models/company_model.dart';
import '../../../../../features/companies/presentation/providers/company_provider.dart';
import '../../../../vehicles/data/repositories/vehicle_repository.dart';
import '../../../../vehicles/data/models/vehicle_model.dart';
import '../../../data/models/booking_model.dart';
import '../../providers/booking_provider.dart';
import '../../../../../shared/widgets/status_badge.dart';
import '../../../../../shared/widgets/wash_type_indicator.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../../shared/utils/status_utils.dart';
import '../../../../../shared/utils/wash_type_utils.dart';

class AdminBookingsListScreen extends ConsumerStatefulWidget {
  const AdminBookingsListScreen({super.key});

  @override
  ConsumerState<AdminBookingsListScreen> createState() => _AdminBookingsListScreenState();
}

class _AdminBookingsListScreenState extends ConsumerState<AdminBookingsListScreen> {
  BookingStatus? _statusFilter;
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);

    if (userAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rezervări')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervări'),
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off_outlined,
              size: 22,
            ),
            tooltip: _showCompleted ? 'Ascunde finalizate' : 'Arată finalizate',
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
          ),
        ],
      ),
      body: Column(
        children: [
          // Inline status filter chips
          _buildStatusFilters(context),
          // Bookings list
          Expanded(
            child: _buildBookingsList(context, bookingsAsync, companiesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = [null, BookingStatus.accepted, BookingStatus.inProgress, BookingStatus.done];
    final labels = ['Toate', 'Acceptate', 'În progres', 'Finalizate'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(statuses.length, (i) {
            final isSelected = _statusFilter == statuses[i];
            return Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(labels[i]),
                selected: isSelected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _statusFilter = statuses[i]);
                },
                selectedColor: AppColors.accent.withValues(alpha: 0.15),
                checkmarkColor: AppColors.accent,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accent : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    AsyncValue<List<BookingModel>> bookingsAsync,
    AsyncValue<List<CompanyModel>> companiesAsync,
  ) {
    return bookingsAsync.when(
      data: (bookings) {
        var filtered = bookings.toList();

        if (!_showCompleted) {
          filtered = filtered.where((b) => b.status != BookingStatus.done).toList();
        }
        if (_statusFilter != null) {
          filtered = filtered.where((b) => b.status == _statusFilter).toList();
        }

        filtered.sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.slotStart.compareTo(b.slotStart);
        });

        if (filtered.isEmpty) {
          return EmptyState(
            icon: AppIcons.bookings,
            title: 'Nu există rezervări',
            subtitle: _statusFilter != null ? 'Încearcă să ajustezi filtrele' : null,
          );
        }

        final groupedByDate = <String, List<MapEntry<BookingModel, CompanyModel?>>>{};
        for (final booking in filtered) {
          final company = companiesAsync.value?.where((c) => c.id == booking.companyId).firstOrNull;
          groupedByDate.putIfAbsent(booking.date, () => []).add(MapEntry(booking, company));
        }
        final sortedDates = groupedByDate.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allBookingsProvider);
            ref.invalidate(allCompaniesProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: sortedDates.length,
            itemBuilder: (context, dateIndex) {
              final date = sortedDates[dateIndex];
              final entries = groupedByDate[date]!;
              final parsedDate = DateTimeUtils.parseDate(date);
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = today.add(const Duration(days: 1));
              final dateOnly = parsedDate != null ? DateTime(parsedDate.year, parsedDate.month, parsedDate.day) : null;

              String dateLabel;
              if (dateOnly == today) {
                dateLabel = 'Astăzi — ${DateTimeUtils.formatDateDisplay(parsedDate!)}';
              } else if (dateOnly == tomorrow) {
                dateLabel = 'Mâine — ${DateTimeUtils.formatDateDisplay(parsedDate!)}';
              } else {
                dateLabel = parsedDate != null ? DateTimeUtils.formatDateDisplay(parsedDate) : date;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                    child: Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ...entries.map((entry) => _AdminBookingCard(
                    booking: entry.key,
                    companyName: entry.value?.name ?? 'Companie necunoscută',
                    companyPhone: entry.value?.phone,
                    onStatusChange: (newStatus) => _updateStatus(entry.key, newStatus),
                  )),
                ],
              );
            },
          ),
        );
      },
      loading: () => ListView(
        children: List.generate(4, (_) => const SkeletonCard()),
      ),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Eroare la încărcarea rezervărilor',
        subtitle: '$error',
        actionLabel: 'Reîncearcă',
        onAction: () {
          ref.invalidate(allBookingsProvider);
          ref.invalidate(allCompaniesProvider);
        },
      ),
    );
  }

  Future<void> _updateStatus(BookingModel booking, BookingStatus newStatus) async {
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final oldStatus = booking.status;
      await repository.updateBookingStatus(booking.id, newStatus);

      final notificationService = NotificationSenderService();
      await notificationService.sendBookingStatusNotification(
        booking: booking,
        oldStatus: oldStatus,
        newStatus: newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status actualizat: ${StatusUtils.label(newStatus)}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String companyName;
  final String? companyPhone;
  final void Function(BookingStatus) onStatusChange;

  const _AdminBookingCard({
    required this.booking,
    required this.companyName,
    this.companyPhone,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transitions = StatusUtils.availableTransitions(booking.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        borderRadius: AppSpacing.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: wash icon + name + wash type + status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WashTypeIndicator(washType: booking.washType),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(companyName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          WashTypeUtils.fullLabel(booking.washType),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Time + address row
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.slotStart} – ${booking.slotEnd}',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.addressText,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Phone - subtle inline
              if (companyPhone != null && companyPhone!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                _PhoneRow(phone: companyPhone!),
              ],
              // Quick actions
              if (transitions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.directions_outlined,
                        size: 20,
                        color: booking.lat != null ? theme.colorScheme.onSurfaceVariant : AppColors.warning,
                      ),
                      onPressed: () {
                        if (booking.lat == null || booking.lng == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Adresa a fost introdusă manual — localizarea poate fi imprecisă.'),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'Deschide',
                                textColor: Colors.white,
                                onPressed: () => MapUtils.openDirections(
                                  addressText: booking.addressText,
                                  lat: booking.lat,
                                  lng: booking.lng,
                                ),
                              ),
                            ),
                          );
                        } else {
                          MapUtils.openDirections(
                            addressText: booking.addressText,
                            lat: booking.lat,
                            lng: booking.lng,
                          );
                        }
                      },
                      tooltip: booking.lat != null ? 'Navighează' : 'Adresă manuală',
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    ...transitions.take(2).map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: _StatusActionChip(
                          status: status,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            onStatusChange(status);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detalii rezervare', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          StatusBadge(status: booking.status, variant: StatusBadgeVariant.dot),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: FutureBuilder<VehicleModel?>(
                    future: _getVehicle(booking.vehicleId),
                    builder: (context, vehicleSnap) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DetailRow(icon: Icons.business_outlined, label: 'Companie', value: companyName),
                          if (companyPhone != null && companyPhone!.trim().isNotEmpty)
                            _PhoneDetailRow(phone: companyPhone!),
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Dată',
                            value: DateTimeUtils.formatDateDisplay(
                              DateTimeUtils.parseDate(booking.date) ?? DateTime.now(),
                            ),
                          ),
                          _DetailRow(icon: Icons.access_time_rounded, label: 'Ora', value: '${booking.slotStart} – ${booking.slotEnd}'),
                          _DetailRow(icon: Icons.location_on_outlined, label: 'Adresă', value: booking.addressText),
                          _DetailRow(
                            icon: WashTypeUtils.icon(booking.washType),
                            label: 'Tip spălare',
                            value: WashTypeUtils.fullLabel(booking.washType),
                          ),
                          if (vehicleSnap.data != null)
                            _DetailRow(icon: Icons.directions_car_outlined, label: 'Mașină', value: vehicleSnap.data!.plateNumber),
                          if (booking.description != null && booking.description!.isNotEmpty)
                            _DetailRow(icon: Icons.note_outlined, label: 'Note', value: booking.description!),
                          const SizedBox(height: AppSpacing.lg),
                          // Actions
                          if (StatusUtils.availableTransitions(booking.status).isNotEmpty) ...[
                            Text('Schimbă statusul', style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppSpacing.sm),
                            ...StatusUtils.availableTransitions(booking.status).map((status) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      onStatusChange(status);
                                    },
                                    icon: Icon(StatusUtils.icon(status), size: 18),
                                    label: Text(StatusUtils.label(status)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: StatusUtils.color(status),
                                      side: BorderSide(color: StatusUtils.color(status).withValues(alpha: 0.3)),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                          // Navigate button
                          const SizedBox(height: AppSpacing.sm),
                          if (booking.lat == null || booking.lng == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Adresa a fost introdusă manual — localizarea poate fi imprecisă.',
                                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => MapUtils.openDirections(
                                addressText: booking.addressText,
                                lat: booking.lat,
                                lng: booking.lng,
                              ),
                              icon: const Icon(Icons.directions_rounded, size: 18),
                              label: Text(
                                booking.lat != null ? 'Navighează pe hartă' : 'Caută adresa pe hartă',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<VehicleModel?> _getVehicle(String vehicleId) async {
    try {
      return await VehicleRepository().getVehicleById(vehicleId);
    } catch (_) {
      return null;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String phone;

  const _PhoneRow({required this.phone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: phone));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Număr copiat: $phone'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onLongPress: () => MapUtils.launchPhone(phone),
      borderRadius: AppSpacing.borderRadiusSm,
      child: Row(
        children: [
          Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            phone,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.copy_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(width: 2),
          Text(
            'Copiază',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneDetailRow extends StatelessWidget {
  final String phone;

  const _PhoneDetailRow({required this.phone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Telefon',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    SelectableText(
                      phone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Număr copiat: $phone'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.copy_rounded, size: 16, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusActionChip extends StatelessWidget {
  final BookingStatus status;
  final VoidCallback onTap;

  const _StatusActionChip({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = StatusUtils.color(status);
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppSpacing.borderRadiusFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(StatusUtils.icon(status), size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                StatusUtils.label(status),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
