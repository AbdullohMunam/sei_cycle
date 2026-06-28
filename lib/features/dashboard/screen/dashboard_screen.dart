import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../../notification/services/notification_service.dart';
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
    _summaryFuture = _loadSummary();
  }

  Future<DashboardSummary> _loadSummary() async {
    final summary = await _service.load(
      includeFinance: widget.profile.canViewFinanceDashboard,
    );
    await _createLowStockAlerts(summary);
    return summary;
  }

  Future<void> _createLowStockAlerts(DashboardSummary summary) async {
    if (!widget.profile.canManageInventory) return;
    final notificationService = NotificationService();
    for (final item in summary.lowStockPreview) {
      try {
        await notificationService.createLowStockAlert(
          userId: widget.profile.uid,
          role: widget.profile.effectiveRole,
          itemId: item.id,
          name: item.name,
          currentStock: item.currentStock,
          minStock: item.minStock,
          unit: item.unit,
        );
      } catch (error, stackTrace) {
        debugPrint('Gagal membuat notifikasi stok rendah: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
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
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
            children: [
              _WelcomePanel(profile: widget.profile),
              const SizedBox(height: 18),
              const SectionTitle(
                title: 'Ringkasan Operasional',
                subtitle: 'Data real-time Kebun Sei hari ini',
                trailing: _LiveBadge(),
              ),
              const SizedBox(height: 12),
              _MetricGrid(
                metrics: [
                  _MetricData(
                    title: 'Total Populasi Ternak',
                    value: '${summary.totalInventoryItems} item',
                    helper: 'Inventaris aktif + stok operasional',
                    icon: Icons.pets_rounded,
                    color: AppColors.primaryGreen,
                    percent: 84,
                  ),
                  _MetricData(
                    title: 'Volume Limbah Terolah',
                    value: '${summary.weeklyLogbooks} catatan/minggu',
                    helper: 'Aktivitas sirkular dari logbook mingguan',
                    icon: Icons.recycling_rounded,
                    color: AppColors.accentBrown,
                    percent: 71,
                  ),
                  _MetricData(
                    title: 'Total Produksi',
                    value: '${summary.todayLogbooks} aktivitas/hari',
                    helper: 'Logbook hari ini dari seluruh modul',
                    icon: Icons.agriculture_outlined,
                    color: AppColors.success,
                    percent: 89,
                  ),
                  _MetricData(
                    title: 'Estimasi Nilai Ekonomi',
                    value: summary.financeVisible
                        ? currencyFormat.format(summary.profitLoss)
                        : '${summary.todaySchedules} jadwal',
                    helper: summary.financeVisible
                        ? 'Laba/rugi sederhana bulan berjalan'
                        : 'Agenda operasional hari ini',
                    icon: Icons.monetization_on_outlined,
                    color: AppColors.warning,
                    percent: 62,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              const SectionTitle(
                title: 'Sistem Aliran Nutrisi',
                subtitle:
                    'Siklus tertutup Kebun Sei - zero waste integrated farming',
              ),
              const SizedBox(height: 10),
              _NutrientCyclePanel(
                nodes: summary.nutrientCycleNodes,
                edges: summary.nutrientCycleEdges,
              ),
              const SizedBox(height: AppSpacing.section),
              const SectionTitle(
                title: 'Aktivitas Hari Ini',
                subtitle: 'Agenda ringkas dan kondisi operasional modul',
              ),
              const SizedBox(height: 10),
              _DashboardTwoColumn(
                left: _ModuleActivityPanel(items: summary.logbooksByModule),
                right: _LowStockPanel(items: summary.lowStockPreview),
              ),
              const SizedBox(height: AppSpacing.section),
              SectionTitle(
                title: 'Aktivitas Tujuh Hari Terakhir',
                subtitle: 'Jumlah catatan logbook yang dibuat per hari.',
                trailing: StatusBadge(
                  label: '${_activityTotal(summary.activities)} catatan',
                  color: AppColors.primaryGreen,
                  icon: Icons.bar_chart_rounded,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                child: SizedBox(
                  height: 180,
                  child: _ActivityChart(points: summary.activities),
                ),
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
        final compact = constraints.maxWidth < 460;
        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.fromLTRB(18, compact ? 18 : 22, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -48,
                child: Container(
                  width: 110,
                  height: 110,
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
                  width: 82,
                  height: 82,
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
                        Row(
                          children: [
                            Text(
                              '${_greeting()}, ${_firstName(profile.name)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.eco_rounded,
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Dashboard SeiCycle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Kebun Sei - Sistem Pertanian & Peternakan Terintegrasi Berbasis Nutrisi Berkelanjutan',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            const _WelcomeBadge(
                              icon: Icons.location_on_outlined,
                              label: 'Pakisaji, Malang',
                            ),
                            _WelcomeBadge(
                              icon: Icons.landscape_outlined,
                              label: profile.roleLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 76,
                      height: 76,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
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

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: AppColors.success),
          SizedBox(width: 7),
          Text(
            'Live',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
            : constraints.maxWidth >= 360
            ? 2
            : 1;
        const spacing = 18.0;
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
    required this.percent,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final int percent;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBox(icon: data.icon, color: data.color, size: 38),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${data.percent}%',
                  style: TextStyle(
                    color: data.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: data.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            data.helper,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data.percent / 100,
              minHeight: 5,
              backgroundColor: data.color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_rounded, color: AppColors.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aliran Nutrisi - Sistem Sirkular Tertutup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Setiap limbah menjadi sumber daya baru dalam ekosistem Kebun Sei.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < nodes.length; index++) ...[
                  _NutrientNodeChip(
                    node: nodes[index],
                    color: _cycleColor(nodes[index].id),
                  ),
                  if (index < nodes.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 7),
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
          InlineMessage(
            icon: Icons.eco_outlined,
            color: AppColors.primaryGreen,
            message:
                'Efisiensi siklus nutrisi tertutup: ${edges.length} alur aktif - hemat input dan pupuk mandiri.',
          ),
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
    return SizedBox(
      width: 82,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Icon(_cycleIcon(node.id), size: 26, color: color),
          ),
          const SizedBox(height: 7),
          Text(
            node.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textMedium,
              height: 1.1,
            ),
          ),
        ],
      ),
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
