import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/operation_feedback.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationService _service;
  String? _type;

  @override
  void initState() {
    super.initState();
    _service = NotificationService();
  }

  Future<void> _markAsRead(AppNotification notification) async {
    await runOperationWithFeedback(
      context,
      operation: () => _service.markAsRead(notification.id),
      successMessage: 'Notifikasi ditandai sudah dibaca.',
    );
  }

  Future<void> _markAllAsRead() async {
    await runOperationWithFeedback(
      context,
      operation: () => _service.markAllAsRead(
        userId: widget.profile.uid,
        role: widget.profile.effectiveRole,
      ),
      successMessage: 'Semua notifikasi ditandai sudah dibaca.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Notifikasi & Pengingat',
      subtitle: 'Otomatis dari sistem logbook Kebun Sei',
      actions: [
        OutlinedButton.icon(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Tandai semua'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _NotificationFilterChip(
                  selected: _type == null,
                  label: 'Semua',
                  icon: Icons.notifications_none_rounded,
                  color: AppColors.info,
                  onSelected: () => setState(() => _type = null),
                ),
                _NotificationFilterChip(
                  selected: _type == 'production_reminder',
                  label: 'Jadwal Pakan',
                  icon: Icons.notifications_none_rounded,
                  color: AppColors.info,
                  onSelected: () =>
                      setState(() => _type = 'production_reminder'),
                ),
                _NotificationFilterChip(
                  selected: _type == 'schedule_overdue',
                  label: 'Peringatan',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  onSelected: () => setState(() => _type = 'schedule_overdue'),
                ),
                _NotificationFilterChip(
                  selected: _type == 'low_stock',
                  label: 'Stok Rendah',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.error,
                  onSelected: () => setState(() => _type = 'low_stock'),
                ),
                _NotificationFilterChip(
                  selected: _type == 'system',
                  label: 'Sistem',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  onSelected: () => setState(() => _type = 'system'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: _service.watchNotifications(
                userId: widget.profile.uid,
                role: widget.profile.effectiveRole,
                type: _type,
              ),
              builder: (context, snapshot) {
                final state = asyncSnapshotState(snapshot);
                if (state != null) return state;

                final notifications = snapshot.requireData;
                if (notifications.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada notifikasi',
                    message:
                        'Alert stok, jadwal, dan sistem akan muncul di sini saat tersedia.',
                    icon: Icons.notifications_none_outlined,
                  );
                }

                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationCard(
                      notification: notification,
                      onMarkRead: notification.isRead
                          ? null
                          : () => _markAsRead(notification),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final VoidCallback? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    return AppCard(
      color: notification.isRead ? AppColors.surface : AppColors.softGreen,
      borderColor: notification.isRead
          ? AppColors.border
          : color.withValues(alpha: 0.35),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: AppIconBox(
                icon: _typeIcon(notification.type),
                color: color,
                size: 42,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMedium,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          label: _typeLabel(notification.type),
                          color: AppColors.primaryGreen,
                        ),
                        StatusBadge(
                          label: notification.scheduledAt == null
                              ? shortDateFormat.format(notification.createdAt)
                              : timeFormat.format(notification.scheduledAt!),
                          color: AppColors.textMuted,
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (onMarkRead != null)
              Center(
                child: IconButton(
                  onPressed: onMarkRead,
                  icon: const Icon(Icons.check_circle_rounded),
                  color: color,
                  tooltip: 'Tandai dibaca',
                ),
              ),
            Container(
              width: 4,
              margin: const EdgeInsets.fromLTRB(8, 18, 12, 18),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onSelected,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        avatar: Icon(icon, size: 15, color: selected ? Colors.white : color),
        label: Text(label),
        selectedColor: color,
        labelStyle: TextStyle(
          color: selected ? Colors.white : color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

Color _typeColor(String type) => switch (type) {
  'low_stock' => AppColors.warning,
  'schedule_overdue' => AppColors.error,
  'production_reminder' => AppColors.primaryGreen,
  _ => AppColors.info,
};

IconData _typeIcon(String type) => switch (type) {
  'low_stock' => Icons.inventory_2_outlined,
  'schedule_overdue' => Icons.event_busy_outlined,
  'production_reminder' => Icons.notifications_active_outlined,
  _ => Icons.info_outline,
};

String _typeLabel(String type) => switch (type) {
  'low_stock' => 'Stok rendah',
  'schedule_overdue' => 'Overdue',
  'production_reminder' => 'Produksi',
  _ => 'Sistem',
};
