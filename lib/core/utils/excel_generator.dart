import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/reports/models/analytics_model.dart';

class ExcelGenerator {
  static Future<void> generateAndShareExcel(AnalyticsModel data) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    _buildSummarySheet(excel, data, dateFormat, currencyFormat);
    _buildLogbooksSheet(excel, data, dateFormat);
    _buildInventorySheet(excel, data);
    _buildFinanceSheet(excel, data, dateFormat);

    // Save and Share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Laporan_SeiCycle_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan Excel SeiCycle');
    }
  }

  static void _buildSummarySheet(Excel excel, AnalyticsModel data, DateFormat dateFormat, NumberFormat currencyFormat) {
    final sheet = excel['Summary'];
    excel.setDefaultSheet('Summary');

    sheet.appendRow([TextCellValue('LAPORAN SEICYCLE')]);
    sheet.appendRow([TextCellValue('Periode: ${dateFormat.format(data.startDate)} - ${dateFormat.format(data.endDate)}')]);
    sheet.appendRow([TextCellValue('')]);
    
    sheet.appendRow([TextCellValue('Total Aktivitas'), IntCellValue(data.logbooks.length)]);
    sheet.appendRow([TextCellValue('Item Stok Rendah'), IntCellValue(data.lowStockItems.length)]);
    sheet.appendRow([TextCellValue('Total Pemasukan'), TextCellValue(currencyFormat.format(data.totalIncome))]);
    sheet.appendRow([TextCellValue('Total Pengeluaran'), TextCellValue(currencyFormat.format(data.totalExpense))]);
    sheet.appendRow([TextCellValue('Laba Bersih'), TextCellValue(currencyFormat.format(data.profitLoss))]);
  }

  static void _buildLogbooksSheet(Excel excel, AnalyticsModel data, DateFormat dateFormat) {
    if (data.logbooks.isEmpty) return;
    
    final sheet = excel['Operasional'];
    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Modul'),
      TextCellValue('Aktivitas'),
      TextCellValue('Kuantitas'),
      TextCellValue('Unit'),
      TextCellValue('Catatan'),
    ]);

    for (final log in data.logbooks) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(log.activityDate)),
        TextCellValue(log.moduleId),
        TextCellValue(log.activityType),
        DoubleCellValue(log.quantity),
        TextCellValue(log.unit),
        TextCellValue(log.note),
      ]);
    }
  }

  static void _buildInventorySheet(Excel excel, AnalyticsModel data) {
    if (data.inventoryItems.isEmpty) return;

    final sheet = excel['Inventaris'];
    sheet.appendRow([
      TextCellValue('Nama Item'),
      TextCellValue('Kategori'),
      TextCellValue('Stok Saat Ini'),
      TextCellValue('Stok Minimum'),
      TextCellValue('Status'),
    ]);

    for (final item in data.inventoryItems) {
      sheet.appendRow([
        TextCellValue(item.name),
        TextCellValue(item.category),
        DoubleCellValue(item.currentStock),
        DoubleCellValue(item.minStock),
        TextCellValue(item.currentStock <= item.minStock ? 'Rendah' : 'Aman'),
      ]);
    }
  }

  static void _buildFinanceSheet(Excel excel, AnalyticsModel data, DateFormat dateFormat) {
    if (data.financeRecords.isEmpty) return;

    final sheet = excel['Keuangan'];
    sheet.appendRow([
      TextCellValue('Tanggal'),
      TextCellValue('Tipe'),
      TextCellValue('Kategori'),
      TextCellValue('Jumlah'),
      TextCellValue('Catatan'),
    ]);

    for (final record in data.financeRecords) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(record.date)),
        TextCellValue(record.type),
        TextCellValue(record.category),
        DoubleCellValue(record.amount),
        TextCellValue(record.note),
      ]);
    }
  }
}
