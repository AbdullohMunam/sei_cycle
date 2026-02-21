import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../widgets/common_widgets.dart';
import '../theme/app_theme.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = AppData.notifications;

    final infoCount = notifications
        .where((n) => n.type == NotifType.info)
        .length;
    final warnCount = notifications
        .where((n) => n.type == NotifType.warning)
        .length;
    final successCount = notifications
        .where((n) => n.type == NotifType.success)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifikasi & Pengingat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Otomatis dari sistem logbook Kebun Sei',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              // Summary chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(
                    label: '$infoCount Jadwal Pakan',
                    color: AppColors.info,
                    icon: Icons.notifications_outlined,
                  ),
                  _SummaryChip(
                    label: '$warnCount Peringatan',
                    color: AppColors.warning,
                    icon: Icons.warning_amber_outlined,
                  ),
                  _SummaryChip(
                    label: '$successCount Est. Panen',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── List ─────────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, i) => AlertTile(data: notifications[i]),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
