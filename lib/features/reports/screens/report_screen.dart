import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/excel_generator.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../models/analytics_model.dart';
import '../models/report_filter.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportService _service;
  late Future<AnalyticsModel> _dataFuture;
  late ReportFilter _filter;

  @override
  void initState() {
    super.initState();
    _service = ReportService();
    
    // Default filter: last 30 days, full summary
    final now = DateTime.now();
    _filter = ReportFilter(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      reportType: ReportType.full_summary,
    );
    _load();
  }

  void _load() {
    setState(() {
      _dataFuture = _service.generateReport(_filter);
    });
  }

  void _exportPdf(AnalyticsModel data) async {
    try {
      await PdfGenerator.generateAndSharePdf(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e')),
        );
      }
    }
  }

  void _exportExcel(AnalyticsModel data) async {
    try {
      await ExcelGenerator.generateAndShareExcel(data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor Excel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: FutureBuilder<AnalyticsModel>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingState(label: 'Memuat data laporan...');
              }
              if (snapshot.hasError) {
                return ErrorState(
                  message: 'Gagal memuat laporan: ${snapshot.error}',
                  onRetry: _load,
                );
              }
              
              final data = snapshot.requireData;
              return _buildContent(data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DateRangePicker(
            startDate: _filter.startDate,
            endDate: _filter.endDate,
            onChanged: (start, end) {
              _filter = _filter.copyWith(startDate: start, endDate: end);
              _load();
            },
          ),
          DropdownButton<ReportType>(
            value: _filter.reportType,
            items: ReportType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                _filter = _filter.copyWith(reportType: val);
                _load();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsModel data) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _exportPdf(data),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _exportExcel(data),
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Total Aktivitas Logbook'),
                trailing: Text('${data.logbooks.length}'),
              ),
              ListTile(
                title: const Text('Item Stok Rendah'),
                trailing: Text('${data.lowStockItems.length}'),
                textColor: data.lowStockItems.isNotEmpty ? Colors.red : null,
              ),
              if (_filter.reportType == ReportType.full_summary || _filter.reportType == ReportType.finance) ...[
                ListTile(
                  title: const Text('Total Pemasukan'),
                  trailing: Text(currencyFormat.format(data.totalIncome), style: const TextStyle(color: Colors.green)),
                ),
                ListTile(
                  title: const Text('Total Pengeluaran'),
                  trailing: Text(currencyFormat.format(data.totalExpense), style: const TextStyle(color: Colors.red)),
                ),
                ListTile(
                  title: const Text('Laba Bersih'),
                  trailing: Text(
                    currencyFormat.format(data.profitLoss),
                    style: TextStyle(
                      color: data.profitLoss >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime, DateTime) onChanged;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM yyyy');
    return OutlinedButton.icon(
      onPressed: () async {
        final result = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: DateTimeRange(start: startDate, end: endDate),
        );
        if (result != null) {
          onChanged(result.start, result.end);
        }
      },
      icon: const Icon(Icons.date_range),
      label: Text('${format.format(startDate)} - ${format.format(endDate)}'),
    );
  }
}
