import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
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
    _load();
  }

  void _load() {
    _summaryFuture = _service.load(
      includeFinance: widget.profile.canViewFinanceDashboard,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _summaryFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingState(label: 'Menyusun ringkasan kebun...');
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Dashboard gagal dimuat: ${snapshot.error}',
            onRetry: () => setState(_load),
          );
        }

        final summary = snapshot.requireData;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _WelcomePanel(profile: widget.profile),
              const SizedBox(height: AppSpacing.section),
              const SectionTitle(
                title: 'Ringkasan operasional',
                subtitle:
                    'Logbook, stok, dan agenda dari data Firestore aktif.',
                trailing: StatusBadge(
                  label: 'Data langsung',
                  color: AppColors.success,
                  icon: Icons.circle,
                ),
              ),
              const SizedBox(height: 12),
              _MetricGrid(
                metrics: [
                  _MetricData(
                    title: 'Aktivitas hari ini',
                    value: '${summary.todayLogbooks}',
                    helper: summary.todayLogbooks == 0
                        ? 'Belum ada logbook hari ini'
                        : 'Logbook masuk hari ini',
                    icon: Icons.today_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  _MetricData(
                    title: 'Aktivitas minggu ini',
                    value: '${summary.weeklyLogbooks}',
                    helper: 'Akumulasi sejak awal minggu',
                    icon: Icons.date_range_outlined,
                    color: AppColors.info,
                  ),
                  _MetricData(
                    title: 'Total item inventaris',
                    value: '${summary.totalInventoryItems}',
                    helper: 'Item aktif dalam inventaris',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.accentBrown,
                  ),
                  _MetricData(
                    title: 'Stok rendah',
                    value: '${summary.lowStockItems}',
                    helper: summary.lowStockItems == 0
                        ? 'Seluruh stok masih aman'
                        : 'Item menyentuh batas minimum',
                    icon: Icons.warning_amber_rounded,
                    color: summary.lowStockItems == 0
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  _MetricData(
                    title: 'Jadwal hari ini',
                    value: '${summary.todaySchedules}',
                    helper: 'Agenda operasional tanggal ini',
                    icon: Icons.event_available_outlined,
                    color: AppColors.primaryGreen,
                  ),
                  _MetricData(
                    title: 'Jadwal terlambat',
                    value: '${summary.overdueSchedules}',
                    helper: summary.pendingSchedules == 0
                        ? 'Tidak ada agenda pending'
                        : '${summary.pendingSchedules} agenda masih pending',
                    icon: Icons.event_busy_outlined,
                    color: summary.overdueSchedules == 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _DashboardTwoColumn(
                left: _ModuleActivityPanel(items: summary.logbooksByModule),
                right: _LowStockPanel(items: summary.lowStockPreview),
              ),
              const SizedBox(height: AppSpacing.section),
              SectionTitle(
                title: 'Aktivitas tujuh hari terakhir',
                subtitle: 'Jumlah catatan logbook yang dibuat per hari.',
                trailing: StatusBadge(
                  label: '${_activityTotal(summary.activities)} catatan',
                  color: AppColors.primaryGreen,
                  icon: Icons.bar_chart_rounded,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                child: SizedBox(
                  height: 230,
                  child: _ActivityChart(points: summary.activities),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              const SectionTitle(
                title: 'Ringkasan ekonomi',
                subtitle: 'Arus kas sederhana untuk bulan berjalan.',
              ),
              const SizedBox(height: 12),
              if (summary.financeVisible)
                _MetricGrid(
                  metrics: [
                    _MetricData(
                      title: 'Pemasukan bulan ini',
                      value: currencyFormat.format(summary.totalIncome),
                      helper: 'Transaksi income bulan berjalan',
                      icon: Icons.south_west_rounded,
                      color: AppColors.success,
                    ),
                    _MetricData(
                      title: 'Pengeluaran bulan ini',
                      value: currencyFormat.format(summary.totalExpense),
                      helper: 'Transaksi expense bulan berjalan',
                      icon: Icons.north_east_rounded,
                      color: AppColors.error,
                    ),
                    _MetricData(
                      title: 'Laba / rugi bulan ini',
                      value: currencyFormat.format(summary.profitLoss),
                      helper: summary.profitLoss >= 0
                          ? 'Arus kas bulan ini positif'
                          : 'Pengeluaran bulan ini lebih besar',
                      icon: Icons.account_balance_wallet_outlined,
                      color: summary.profitLoss >= 0
                          ? AppColors.primaryGreen
                          : AppColors.warning,
                    ),
                  ],
                )
              else
                const InlineMessage(
                  icon: Icons.lock_outline,
                  color: AppColors.accentBrown,
                  message:
                      'Ringkasan keuangan belum dapat ditampilkan untuk akun ini.',
                ),
              const SizedBox(height: AppSpacing.section),
              const SectionTitle(
                title: 'Siklus nutrisi',
                subtitle:
                    'Alur ekonomi sirkular dari ayam, organik, maggot, cacing, lele, dan tanaman.',
              ),
              const SizedBox(height: 12),
              _NutrientCyclePanel(
                nodes: summary.nutrientCycleNodes,
                edges: summary.nutrientCycleEdges,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -48,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 46,
                bottom: -54,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, ${_firstName(profile.name)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Kebun Sei hari ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pantau pencatatan, stok, agenda, dan siklus nutrisi dari satu tempat.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const _WelcomeBadge(
                              icon: Icons.location_on_outlined,
                              label: 'Kebun Sei',
                            ),
                            _WelcomeBadge(
                              icon: Icons.badge_outlined,
                              label: profile.roleLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 18),
                    Container(
                      width: 74,
                      height: 74,
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'lib/assets/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.eco_rounded,
                          color: AppColors.primaryGreen,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeBadge extends StatelessWidget {
  const _WelcomeBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTwoColumn extends StatelessWidget {
  const _DashboardTwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ModuleActivityPanel extends StatelessWidget {
  const _ModuleActivityPanel({required this.items});

  final List<ModuleActivitySummary> items;

  @override
  Widget build(BuildContext context) {
    final maxTotal = items.fold<int>(
      0,
      (current, item) => item.total > current ? item.total : current,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas per modul',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _ModuleActivityRow(item: item, maxTotal: maxTotal),
            if (item != items.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ModuleActivityRow extends StatelessWidget {
  const _ModuleActivityRow({required this.item, required this.maxTotal});

  final ModuleActivitySummary item;
  final int maxTotal;

  @override
  Widget build(BuildContext context) {
    final progress = maxTotal == 0 ? 0.0 : item.total / maxTotal;
    final color = _moduleColor(item.moduleType);
    return Row(
      children: [
        AppIconBox(icon: _moduleIcon(item.moduleType), color: color, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${item.total}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.progressBg,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LowStockPanel extends StatelessWidget {
  const _LowStockPanel({required this.items});

  final List<LowStockDashboardItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stok rendah teratas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const InlineMessage(
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              message: 'Tidak ada stok yang berada di bawah batas minimum.',
            )
          else
            for (final item in items) ...[
              _LowStockRow(item: item),
              if (item != items.last) const Divider(height: 18),
            ],
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.item});

  final LowStockDashboardItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${_number(item.currentStock)} / ${_number(item.minStock)} ${item.unit}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 960
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _MetricCard(data: metric),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(icon: data.icon, color: data.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: data.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.helper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.points});

  final List<DailyActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxTotal = points.fold<int>(
      0,
      (current, point) => point.total > current ? point.total : current,
    );
    return BarChart(
      BarChartData(
        maxY: (maxTotal + 2).toDouble(),
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border.withValues(alpha: 0.8),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('E', 'id_ID').format(points[index].date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].total.toDouble(),
                  width: 18,
                  color: points[index].total == 0
                      ? AppColors.progressBg
                      : AppColors.primaryGreen,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NutrientCyclePanel extends StatelessWidget {
  const _NutrientCyclePanel({required this.nodes, required this.edges});

  final List<NutrientCycleNode> nodes;
  final List<NutrientCycleEdge> edges;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final node in nodes)
                _NutrientNodeChip(node: node, color: _cycleColor(node.id)),
            ],
          ),
          const SizedBox(height: 16),
          for (final edge in edges) ...[
            _NutrientEdgeRow(edge: edge),
            if (edge != edges.last) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _NutrientNodeChip extends StatelessWidget {
  const _NutrientNodeChip({required this.node, required this.color});

  final NutrientCycleNode node;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 230),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_cycleIcon(node.id), size: 20, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    node.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.3,
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

class _NutrientEdgeRow extends StatelessWidget {
  const _NutrientEdgeRow({required this.edge});

  final NutrientCycleEdge edge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.primaryGreen,
          size: 18,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_cycleLabel(edge.from)} ke ${_cycleLabel(edge.to)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' melalui ${edge.label}'),
              ],
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
          ),
        ),
      ],
    );
  }
}

int _activityTotal(List<DailyActivityPoint> points) =>
    points.fold(0, (total, point) => total + point.total);

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 19) return 'Selamat sore';
  return 'Selamat malam';
}

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Rekan Kebun';
  return trimmed.split(RegExp(r'\s+')).first;
}

Color _moduleColor(String moduleType) => switch (moduleType) {
  'ayam_kampung' => AppColors.warning,
  'maggot_bsf' => AppColors.accentBrown,
  'cacing_tanah' => AppColors.primaryGreen,
  'lele' => AppColors.info,
  'tanaman' => AppColors.success,
  _ => AppColors.textMuted,
};

IconData _moduleIcon(String moduleType) => switch (moduleType) {
  'ayam_kampung' => Icons.egg_alt_outlined,
  'maggot_bsf' => Icons.pest_control_outlined,
  'cacing_tanah' => Icons.grass_outlined,
  'lele' => Icons.water_drop_outlined,
  'tanaman' => Icons.eco_outlined,
  _ => Icons.category_outlined,
};

Color _cycleColor(String id) => switch (id) {
  'ayam' => AppColors.warning,
  'organik' => AppColors.accentBrown,
  'maggot_cacing' => AppColors.primaryGreen,
  'kompos' => AppColors.success,
  'lele_tanaman' => AppColors.info,
  _ => AppColors.textMuted,
};

IconData _cycleIcon(String id) => switch (id) {
  'ayam' => Icons.egg_alt_outlined,
  'organik' => Icons.recycling_rounded,
  'maggot_cacing' => Icons.pest_control_outlined,
  'kompos' => Icons.compost_outlined,
  'lele_tanaman' => Icons.water_drop_outlined,
  _ => Icons.eco_outlined,
};

String _cycleLabel(String id) => switch (id) {
  'ayam' => 'Ayam',
  'organik' => 'Sisa organik',
  'maggot_cacing' => 'Maggot/cacing',
  'kompos' => 'Kompos',
  'lele_tanaman' => 'Lele/tanaman',
  _ => id,
};
