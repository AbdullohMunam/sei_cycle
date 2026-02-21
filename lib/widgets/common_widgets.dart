import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';

class StatCard extends StatelessWidget {
  final StatCardData data;

  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(data.progress * 100).toInt()}%',
                    style: TextStyle(
                      color: data.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: data.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(data.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              data.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: data.progress,
                backgroundColor: data.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(data.color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nutrient Flow Card ───────────────────────────────────────────────────────

class NutrientFlowCard extends StatelessWidget {
  const NutrientFlowCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.loop, color: AppColors.primaryGreen, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Aliran Nutrisi – Sistem Sirkular Tertutup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Setiap limbah menjadi sumber daya baru dalam ekosistem Kebun Sei.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            _FlowDiagram(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.progressBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Efisiensi siklus nutrisi tertutup: 0 limbah ke TPA · Hemat pakan 60% · Pupuk mandiri 100%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primaryGreenDark,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowDiagram extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final flows = AppData.nutrientFlow;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(flows.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Arrow
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            );
          }
          final item = flows[i ~/ 2];
          final color = item['color'] as Color;
          return _FlowNode(
            label: item['label'] as String,
            icon: item['icon'] as IconData,
            color: color,
          );
        }),
      ),
    );
  }
}

class _FlowNode extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _FlowNode({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.13),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Alert Tile ───────────────────────────────────────────────────────────────

class AlertTile extends StatelessWidget {
  final NotifData data;

  const AlertTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(data.icon, color: data.color, size: 22),
        ),
        title: Text(
          data.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              data.body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                _Chip(label: data.module, color: AppColors.primaryGreen),
                _Chip(label: '🕐 ${data.time}', color: AppColors.textMuted),
              ],
            ),
          ],
        ),
        trailing: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: data.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
