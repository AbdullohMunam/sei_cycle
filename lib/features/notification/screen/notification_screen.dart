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
      title: 'Notifikasi',
      subtitle: 'Pengingat in-app dan alert ringan tanpa backend server.',
      actions: [
        OutlinedButton.icon(
          onPressed: _markAllAsRead,
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Tandai semua'),
        ),
      ],
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String?>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Filter tipe'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua notifikasi')),
                DropdownMenuItem(
                  value: 'low_stock',
                  child: Text('Stok rendah'),
                ),
                DropdownMenuItem(
                  value: 'schedule_overdue',
                  child: Text('Jadwal overdue'),
                ),
                DropdownMenuItem(
                  value: 'production_reminder',
                  child: Text('Pengingat produksi'),
                ),
                DropdownMenuItem(value: 'system', child: Text('Sistem')),
              ],
              onChanged: (value) => setState(() => _type = value),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(icon: _typeIcon(notification.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: _typeLabel(notification.type),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: notification.isRead ? 'Dibaca' : 'Baru',
                      color: notification.isRead
                          ? AppColors.textMuted
                          : AppColors.primaryGreen,
                      icon: notification.isRead
                          ? Icons.mark_email_read_outlined
                          : Icons.fiber_new_rounded,
                    ),
                    StatusBadge(
                      label: shortDateFormat.format(notification.createdAt),
                      color: AppColors.info,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onMarkRead != null)
            IconButton(
              onPressed: onMarkRead,
              icon: const Icon(Icons.done_rounded),
              tooltip: 'Tandai dibaca',
            ),
        ],
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
