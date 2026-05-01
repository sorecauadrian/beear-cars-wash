import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_sender_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/map_utils.dart';
import '../../../../features/bookings/data/models/booking_model.dart';
import '../../../../features/bookings/data/repositories/booking_repository.dart';
import '../../../../features/bookings/presentation/providers/booking_provider.dart';
import '../../../../features/companies/data/repositories/company_repository.dart';
import '../../../../features/vehicles/data/repositories/vehicle_repository.dart';
import '../../../../shared/utils/status_utils.dart';
import '../../../../shared/utils/wash_type_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Future<void> _markAsRead(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (_) {}
  }

  Future<void> _deleteAll(List<NotificationModel> notifications) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge toate notificările'),
        content:
            const Text('Ești sigur că vrei să ștergi toate notificările?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Șterge tot',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in notifications) {
        batch.delete(FirebaseFirestore.instance
            .collection('notifications')
            .doc(n.id));
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _updateStatus(
      BookingModel booking, BookingStatus newStatus) async {
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final oldStatus = booking.status;
      await repository.updateBookingStatus(booking.id, newStatus);
      await NotificationSenderService().sendBookingStatusNotification(
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
            content: Text('Eroare: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _openNotification(NotificationModel notification, bool isAdmin) {
    if (!notification.isRead) _markAsRead(notification.id);

    if (notification.bookingId == null || notification.bookingId!.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BookingDetailSheet(
        bookingId: notification.bookingId!,
        isAdmin: isAdmin,
        onStatusChange: isAdmin
            ? (booking, newStatus) {
                Navigator.pop(context);
                _updateStatus(booking, newStatus);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final isAdmin = userAsync.whenOrNull(data: (u) => u?.isAdmin) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificări'),
        actions: [
          notificationsAsync.whenOrNull(
                data: (list) => list.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        tooltip: 'Șterge tot',
                        onPressed: () => _deleteAll(list),
                      ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nicio notificare',
              subtitle: 'Vei fi notificat despre schimbările rezervărilor.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userNotificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final hasBooking =
                    n.bookingId != null && n.bookingId!.isNotEmpty;
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(n.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusLg,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                  ),
                  child: _NotificationCard(
                    notification: n,
                    hasBooking: hasBooking,
                    onTap: () => _openNotification(n, isAdmin),
                  ),
                );
              },
            ),
          );
        },
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: List.generate(4, (_) => const SkeletonCard()),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Eroare',
          subtitle: '$error',
          actionLabel: 'Încearcă din nou',
          onAction: () => ref.invalidate(userNotificationsProvider),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Notification card
// ─────────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool hasBooking;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.hasBooking,
    required this.onTap,
  });

  IconData _icon() {
    final s = notification.status ?? '';
    if (s.contains('accepted')) return Icons.check_circle_outline_rounded;
    if (s.contains('rejected') || s.contains('cancelled')) {
      return Icons.cancel_outlined;
    }
    if (s.contains('inProgress')) return Icons.local_car_wash_rounded;
    if (s.contains('done')) return Icons.task_alt_rounded;
    if (s.contains('requested')) return Icons.pending_outlined;
    return Icons.notifications_none_rounded;
  }

  Color _color() {
    final s = notification.status ?? '';
    if (s.contains('accepted') || s.contains('done')) return AppColors.success;
    if (s.contains('rejected') || s.contains('cancelled')) {
      return AppColors.error;
    }
    if (s.contains('inProgress')) return AppColors.warning;
    return AppColors.info;
  }

  String _timeLabel() {
    final dt = notification.createdAt;
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Acum';
    if (diff.inMinutes < 60) return 'Acum ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Acum ${diff.inHours}h';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}, $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color();
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isUnread
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : theme.colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(
          color: isUnread
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : theme.colorScheme.outline.withValues(alpha: 0.5),
          width: isUnread ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(_icon(), size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Unread dot
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _timeLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasBooking)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(Icons.chevron_right,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Booking detail bottom sheet
// ─────────────────────────────────────────────────────────────

class _BookingDetailSheet extends StatefulWidget {
  final String bookingId;
  final bool isAdmin;
  final void Function(BookingModel, BookingStatus)? onStatusChange;

  const _BookingDetailSheet({
    required this.bookingId,
    required this.isAdmin,
    this.onStatusChange,
  });

  @override
  State<_BookingDetailSheet> createState() => _BookingDetailSheetState();
}

class _BookingDetailSheetState extends State<_BookingDetailSheet> {
  late Future<_SheetData?> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_SheetData?> _load() async {
    final booking =
        await BookingRepository().getBookingById(widget.bookingId);
    if (booking == null) return null;

    String companyName = '';
    String? companyPhone;
    if (widget.isAdmin) {
      try {
        final company =
            await CompanyRepository().getCompanyById(booking.companyId);
        companyName = company?.name ?? '';
        companyPhone = company?.phone;
      } catch (_) {}
    }

    String? vehiclePlate;
    try {
      final vehicle =
          await VehicleRepository().getVehicleById(booking.vehicleId);
      vehiclePlate = vehicle?.plateNumber;
    } catch (_) {}

    return _SheetData(
      booking: booking,
      companyName: companyName,
      companyPhone: companyPhone,
      vehiclePlate: vehiclePlate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Title row (theme already adds the drag handle pill above)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Detalii rezervare',
                        style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<_SheetData?>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data;
                  if (data == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text('Rezervarea nu a fost găsită.',
                            style: theme.textTheme.bodyMedium),
                      ),
                    );
                  }
                  return _SheetBody(
                    data: data,
                    isAdmin: widget.isAdmin,
                    onStatusChange: widget.onStatusChange,
                    scrollController: scrollController,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetData {
  final BookingModel booking;
  final String companyName;
  final String? companyPhone;
  final String? vehiclePlate;

  const _SheetData({
    required this.booking,
    required this.companyName,
    this.companyPhone,
    this.vehiclePlate,
  });
}

class _SheetBody extends StatelessWidget {
  final _SheetData data;
  final bool isAdmin;
  final void Function(BookingModel, BookingStatus)? onStatusChange;
  final ScrollController scrollController;

  const _SheetBody({
    required this.data,
    required this.isAdmin,
    required this.onStatusChange,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final booking = data.booking;
    final transitions = StatusUtils.availableTransitions(booking.status);
    final dateDisplay = DateTimeUtils.formatDateDisplay(
        DateTimeUtils.parseDate(booking.date) ?? DateTime.now());

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(status: booking.status, variant: StatusBadgeVariant.dot),
          const SizedBox(height: AppSpacing.lg),

          if (isAdmin && data.companyName.isNotEmpty)
            _DetailRow(
                icon: Icons.business_outlined,
                label: 'Companie',
                value: data.companyName),
          if (isAdmin &&
              data.companyPhone != null &&
              data.companyPhone!.isNotEmpty)
            _PhoneTile(phone: data.companyPhone!),
          _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Dată',
              value: dateDisplay),
          _DetailRow(
              icon: Icons.access_time_rounded,
              label: 'Ora',
              value: '${booking.slotStart} – ${booking.slotEnd}'),
          _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Adresă',
              value: booking.addressText),
          _DetailRow(
              icon: WashTypeUtils.icon(booking.washType),
              label: 'Tip spălare',
              value: WashTypeUtils.fullLabel(booking.washType)),
          if (data.vehiclePlate != null)
            _DetailRow(
                icon: Icons.directions_car_outlined,
                label: 'Mașină',
                value: data.vehiclePlate!),
          if (booking.description != null && booking.description!.isNotEmpty)
            _DetailRow(
                icon: Icons.note_outlined,
                label: 'Note',
                value: booking.description!),

          // Admin: status change actions
          if (isAdmin && transitions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Schimbă statusul',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ...transitions.map((status) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onStatusChange?.call(booking, status);
                      },
                      icon: Icon(StatusUtils.icon(status), size: 18),
                      label: Text(StatusUtils.label(status)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StatusUtils.color(status),
                        side: BorderSide(
                            color: StatusUtils.color(status)
                                .withValues(alpha: 0.4)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                )),
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
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adresa a fost introdusă manual — localizarea poate fi imprecisă.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.warning),
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
              label: Text(booking.lat != null
                  ? 'Navighează pe hartă'
                  : 'Caută adresa pe hartă'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

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
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneTile extends StatelessWidget {
  final String phone;
  const _PhoneTile({required this.phone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_outlined,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Telefon',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    SelectableText(
                      phone,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
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
                        child: Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.accent),
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
