import 'package:flutter/material.dart';

import '../../../core/utils/delete_confirmation.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/operation_feedback.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../models/finance_record.dart';
import '../services/finance_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late final FinanceService _service;

  @override
  void initState() {
    super.initState();
    _service = FinanceService();
  }

  Future<void> _openForm([FinanceRecord? record]) async {
    final value = await showDialog<_FinanceFormValue>(
      context: context,
      builder: (_) => _FinanceFormDialog(record: record),
    );
    if (value == null || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.save(
        id: record?.id,
        type: value.type,
        category: value.category,
        amount: value.amount,
        date: value.date,
        note: value.note,
        userId: widget.profile.uid,
      ),
      successMessage: record == null
          ? 'Transaksi ditambahkan.'
          : 'Transaksi diperbarui.',
    );
  }

  Future<void> _delete(FinanceRecord record) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus transaksi?',
      message: 'Transaksi ${record.category} akan dihapus dari laporan.',
    );
    if (!confirmed || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.delete(record.id, userId: widget.profile.uid),
      successMessage: 'Transaksi dihapus.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Keuangan',
      subtitle: 'Catat arus kas sederhana untuk kebutuhan operasional kebun.',
      actions: [
        if (widget.profile.canManageFinance)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah transaksi'),
          ),
      ],
      child: StreamBuilder<List<FinanceRecord>>(
        stream: _service.watchRecords(),
        builder: (context, snapshot) {
          final state = asyncSnapshotState(snapshot);
          if (state != null) return state;
          final records = snapshot.requireData;
          final income = records
              .where((record) => record.type == 'income')
              .fold<double>(0, (total, record) => total + record.amount);
          final expense = records
              .where((record) => record.type == 'expense')
              .fold<double>(0, (total, record) => total + record.amount);

          return Column(
            children: [
              _FinanceSummary(
                income: income,
                expense: expense,
                balance: income - expense,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: records.isEmpty
                    ? const EmptyState(
                        title: 'Belum ada transaksi',
                        message:
                            'Data akan muncul setelah pemasukan atau pengeluaran pertama dicatat.',
                        icon: Icons.account_balance_wallet_outlined,
                      )
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _FinanceRecordCard(
                          record: records[index],
                          canEdit: widget.profile.canManageFinance,
                          canDelete: widget.profile.canDeleteFinance,
                          onEdit: () => _openForm(records[index]),
                          onDelete: () => _delete(records[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceSummary extends StatelessWidget {
  const _FinanceSummary({
    required this.income,
    required this.expense,
    required this.balance,
  });

  final double income;
  final double expense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 820
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        final cards = [
          _FinanceTotalCard(
            label: 'Pemasukan',
            value: income,
            color: AppColors.success,
            icon: Icons.south_west_rounded,
          ),
          _FinanceTotalCard(
            label: 'Pengeluaran',
            value: expense,
            color: AppColors.error,
            icon: Icons.north_east_rounded,
          ),
          _FinanceTotalCard(
            label: 'Laba / rugi',
            value: balance,
            color: balance >= 0 ? AppColors.primaryGreen : AppColors.warning,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }
}

class _FinanceTotalCard extends StatelessWidget {
  const _FinanceTotalCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppIconBox(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyFormat.format(value),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceRecordCard extends StatelessWidget {
  const _FinanceRecordCard({
    required this.record,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final FinanceRecord record;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isIncome = record.type == 'income';
    final color = isIncome ? AppColors.success : AppColors.error;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(
            icon: isIncome
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
            color: color,
          ),
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
                        record.category,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: isIncome ? 'Pemasukan' : 'Pengeluaran',
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  shortDateFormat.format(record.date),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
                if (record.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    record.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currencyFormat.format(record.amount),
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: color),
                      ),
                    ),
                    if (canEdit || canDelete)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canEdit)
                            IconButton(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 19),
                              tooltip: 'Edit transaksi',
                            ),
                          if (canDelete)
                            IconButton(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 19,
                                color: AppColors.error,
                              ),
                              tooltip: 'Hapus transaksi',
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceFormValue {
  const _FinanceFormValue({
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String type;
  final String category;
  final double amount;
  final DateTime date;
  final String note;
}

class _FinanceFormDialog extends StatefulWidget {
  const _FinanceFormDialog({this.record});

  final FinanceRecord? record;

  @override
  State<_FinanceFormDialog> createState() => _FinanceFormDialogState();
}

class _FinanceFormDialogState extends State<_FinanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _category;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String _type;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _category = TextEditingController(text: record?.category);
    _amount = TextEditingController(
      text: record == null ? '' : record.amount.toString(),
    );
    _note = TextEditingController(text: record?.note);
    _type = record?.type ?? 'income';
    _date = record?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? _parsedAmount() =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.'));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _FinanceFormValue(
        type: _type,
        category: _category.text,
        amount: _parsedAmount()!,
        date: _date,
        note: _note.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.record == null ? 'Tambah Transaksi' : 'Edit Transaksi',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 'income',
                        label: Text('Pemasukan'),
                        icon: Icon(Icons.trending_up),
                      ),
                      ButtonSegment(
                        value: 'expense',
                        label: Text('Pengeluaran'),
                        icon: Icon(Icons.trending_down),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() => _type = value.first);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Contoh: penjualan telur',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nominal',
                    prefixText: 'Rp ',
                  ),
                  validator: (_) {
                    final value = _parsedAmount();
                    return value == null || value <= 0
                        ? 'Nominal harus lebih dari 0'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                AppMenuCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Tanggal transaksi',
                  subtitle: shortDateFormat.format(_date),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final result = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (result != null) setState(() => _date = result);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Keterangan singkat transaksi (opsional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
