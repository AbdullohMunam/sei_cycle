import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_state_widgets.dart';
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
    _summaryFuture = _service.load(includeFinance: widget.profile.isAdmin);
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
          return const LoadingState(label: 'Menyusun dashboard...');
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'Dashboard gagal dimuat: ${snapshot.error}',
            onRetry: () => setState(_load),
          );
        }
        final summary = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _WelcomeCard(profile: widget.profile),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1000
                      ? 3
                      : width >= 620
                      ? 2
                      : 1;
                  final itemWidth = (width - ((columns - 1) * 12)) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        width: itemWidth,
                        title: 'Logbook hari ini',
                        value: '${summary.todayLogbooks}',
                        icon: Icons.menu_book_outlined,
                        color: Colors.green,
                      ),
                      _MetricCard(
                        width: itemWidth,
                        title: 'Stok rendah',
                        value: '${summary.lowStockItems}',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.orange,
                      ),
                      _MetricCard(
                        width: itemWidth,
                        title: 'Jadwal pending',
                        value: '${summary.pendingSchedules}',
                        icon: Icons.event_note_outlined,
                        color: Colors.blue,
                      ),
                      _MetricCard(
                        width: itemWidth,
                        title: 'Total pemasukan',
                        value: summary.financeVisible
                            ? currencyFormat.format(summary.totalIncome)
                            : 'Khusus admin',
                        icon: Icons.trending_up,
                        color: Colors.teal,
                      ),
                      _MetricCard(
                        width: itemWidth,
                        title: 'Total pengeluaran',
                        value: summary.financeVisible
                            ? currencyFormat.format(summary.totalExpense)
                            : 'Khusus admin',
                        icon: Icons.trending_down,
                        color: Colors.redAccent,
                      ),
                      _MetricCard(
                        width: itemWidth,
                        title: 'Laba / rugi',
                        value: summary.financeVisible
                            ? currencyFormat.format(summary.profitLoss)
                            : 'Khusus admin',
                        icon: Icons.account_balance_wallet_outlined,
                        color: summary.profitLoss >= 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas 7 hari terakhir',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text('Jumlah catatan logbook per hari.'),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 240,
                        child: _ActivityChart(points: summary.activities),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${profile.name}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ringkasan operasional Kebun Sei - role ${profile.role}',
                    style: const TextStyle(color: Colors.white70),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
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
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].total.toDouble(),
                  width: 20,
                  color: Theme.of(context).colorScheme.primary,
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
