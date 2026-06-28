import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _service;
  late Future<DashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _service = DashboardService();
    _summaryFuture = _service.getDashboardSummary(
      includeFinance: widget.profile.canViewFinanceDashboard,
    );
  }

  void _reload() {
    setState(() {
      _summaryFuture = _service.getDashboardSummary(
        includeFinance: widget.profile.canViewFinanceDashboard,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        final summary = snapshot.data ?? _fallbackSummary;
        final loading = snapshot.connectionState != ConnectionState.done;
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeHeader(),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Ringkasan Operasional',
                  subtitle: loading
                      ? 'Mengambil data Firestore hari ini...'
                      : 'Data real-time Kebun Sei hari ini',
                  trailing: _HeaderLiveBadge(
                    label: snapshot.hasError ? 'Fallback' : 'Live',
                    color: snapshot.hasError
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
                _StatsGrid(summary: summary),
                const SizedBox(height: 28),
                const SectionHeader(
                  title: 'Sistem Aliran Nutrisi',
                  subtitle:
                      'Siklus tertutup Kebun Sei - zero waste integrated farming',
                ),
                const NutrientFlowCard(),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Aktivitas Hari Ini',
                  subtitle: DateFormat(
                    'EEEE, d MMMM yyyy',
                    'id_ID',
                  ).format(DateTime.now()),
                ),
                _ActivityTimeline(activities: summary.recentActivities),
                const SizedBox(height: 28),
                _RevenueCard(summary: summary),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dashboard SeiCycle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kebun Sei - Sistem Pertanian & Peternakan Terintegrasi Berbasis Nutrisi Berkelanjutan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderBadge(
                      icon: Icons.location_on_outlined,
                      label: 'Pakisaji, Malang',
                    ),
                    _HeaderBadge(
                      icon: Icons.area_chart_outlined,
                      label: '+/-500 m2',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'lib/assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.eco_outlined,
                color: AppColors.primaryGreen,
                size: 44,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderLiveBadge extends StatelessWidget {
  const _HeaderLiveBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: Icon(Icons.circle, color: color, size: 10),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(
        title: 'Modul Aktif',
        value: '${summary.activeModuleCount}',
        helper: 'farm_modules aktif',
        icon: Icons.hub_outlined,
        color: AppColors.primaryGreen,
      ),
      _StatData(
        title: 'Aktivitas Hari Ini',
        value: '${summary.todayLogCount}',
        helper: 'catatan logbook',
        icon: Icons.edit_note_outlined,
        color: AppColors.warning,
      ),
      _StatData(
        title: 'Stok Rendah',
        value: '${summary.lowStockCount}',
        helper: 'item perlu dipantau',
        icon: Icons.inventory_2_outlined,
        color: AppColors.error,
      ),
      _StatData(
        title: 'Jadwal Hari Ini',
        value: '${summary.todayScheduleCount}',
        helper: 'agenda operasional',
        icon: Icons.event_note_outlined,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 4 : 2;
        final childAspectRatio = constraints.maxWidth >= 900
            ? 1.05
            : (constraints.maxWidth >= 600 ? 1.1 : 0.95);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: stats.length,
          itemBuilder: (context, i) => _StatCard(data: stats[i]),
        );
      },
    );
  }
}

class _StatData {
  const _StatData({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const Spacer(),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: data.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class NutrientFlowCard extends StatelessWidget {
  const NutrientFlowCard({super.key});

  @override
  Widget build(BuildContext context) {
    const nodes = [
      _FlowNode('Ayam', Icons.egg_alt_outlined, AppColors.warning),
      _FlowNode('Limbah', Icons.recycling_outlined, AppColors.accentBrown),
      _FlowNode(
        'Maggot',
        Icons.bug_report_outlined,
        AppColors.accentLightGreen,
      ),
      _FlowNode('Cacing', Icons.grass_outlined, AppColors.primaryGreen),
      _FlowNode('Lele', Icons.water_drop_outlined, AppColors.info),
      _FlowNode('Tanaman', Icons.eco_outlined, AppColors.success),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < nodes.length; index++) ...[
                    _FlowChip(node: nodes[index]),
                    if (index < nodes.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Setiap limbah menjadi sumber daya baru: kotoran dan sisa organik diolah maggot/cacing, lalu kembali menjadi pakan, kascing, dan nutrisi tanaman.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowNode {
  const _FlowNode(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({required this.node});

  final _FlowNode node;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: node.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(node.icon, color: node.color, size: 25),
          ),
          const SizedBox(height: 7),
          Text(
            node.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.activities});

  final List<DashboardActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(activities.length, (i) {
            final activity = activities[i];
            final isLast = i == activities.length - 1;
            return _TimelineRow(activity: activity, isLast: isLast);
          }),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.activity, required this.isLast});

  final DashboardActivity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              activity.time,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: activity.done
                      ? activity.color
                      : activity.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity.done ? Icons.check : activity.icon,
                  color: activity.done ? Colors.white : activity.color,
                  size: 14,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.progressBg,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: activity.done
                            ? AppColors.textMuted
                            : AppColors.textDark,
                        decoration: activity.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        fontWeight: activity.done
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (activity.done)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.financeVisible && summary.hasFinanceData
        ? summary.monthlyIncome
        : 20000000.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rincian Omset Bulanan - ${_money(total)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              summary.financeVisible && summary.hasFinanceData
                  ? 'Pengeluaran ${_money(summary.monthlyExpense)} - laba/rugi ${_money(summary.monthlyProfit)}'
                  : 'Proyeksi periode Juni-Agustus 2025: Rp 96 jt',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ...summary.revenueItems.map((item) => _RevenueRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({required this.item});

  final RevenueBreakdownItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.portion.clamp(0, 1),
                backgroundColor: item.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(item.color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              _money(item.amount),
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: item.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _fallbackSummary = DashboardSummary(
  activeModuleCount: 5,
  todayLogCount: 0,
  todayScheduleCount: 0,
  lowStockCount: 0,
  monthlyIncome: 0,
  monthlyExpense: 0,
  monthlyProfit: 0,
  recentActivities: fallbackActivities,
  revenueItems: fallbackRevenueItems,
  lowStockPreview: const [],
  financeVisible: false,
);

String _money(double value) {
  final abs = value.abs();
  final prefix = value < 0 ? '-Rp ' : 'Rp ';
  if (abs >= 1000000) {
    final amount = abs / 1000000;
    return '$prefix${amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(1)} jt';
  }
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
}
