import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
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
    if (value == null) return;
    await _service.save(
      id: record?.id,
      type: value.type,
      category: value.category,
      amount: value.amount,
      date: value.date,
      note: value.note,
      userId: widget.profile.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Keuangan',
      subtitle: 'Pemasukan, pengeluaran, dan laba rugi sederhana.',
      actions: [
        FilledButton.icon(
          onPressed: _openForm,
          icon: const Icon(Icons.add),
          label: const Text('Tambah transaksi'),
        ),
      ],
      child: StreamBuilder<List<FinanceRecord>>(
        stream: _service.watchRecords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingState();
          if (snapshot.hasError) {
            return ErrorState(message: '${snapshot.error}');
          }
          final records = snapshot.data!;
          final income = records
              .where((record) => record.type == 'income')
              .fold<double>(0, (total, record) => total + record.amount);
          final expense = records
              .where((record) => record.type == 'expense')
              .fold<double>(0, (total, record) => total + record.amount);
          return Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FinanceTotalCard(
                    label: 'Pemasukan',
                    value: income,
                    color: Colors.green,
                  ),
                  _FinanceTotalCard(
                    label: 'Pengeluaran',
                    value: expense,
                    color: Colors.red,
                  ),
                  _FinanceTotalCard(
                    label: 'Laba / rugi',
                    value: income - expense,
                    color: income - expense >= 0 ? Colors.blue : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: records.isEmpty
                    ? const EmptyState(
                        title: 'Belum ada transaksi',
                        message: 'Tambahkan pemasukan atau pengeluaran.',
                        icon: Icons.account_balance_wallet_outlined,
                      )
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          final isIncome = record.type == 'income';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    (isIncome ? Colors.green : Colors.red)
                                        .withValues(alpha: 0.12),
                                foregroundColor: isIncome
                                    ? Colors.green
                                    : Colors.red,
                                child: Icon(
                                  isIncome
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                ),
                              ),
                              title: Text(record.category),
                              subtitle: Text(
                                '${shortDateFormat.format(record.date)} · '
                                '${record.note}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currencyFormat.format(record.amount),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    onPressed: () => _openForm(record),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceTotalCard extends StatelessWidget {
  const _FinanceTotalCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 6),
              Text(
                currencyFormat.format(value),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: color),
              ),
            ],
          ),
        ),
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
                SegmentedButton<String>(
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Nominal'),
                  validator: (_) {
                    final value = _parsedAmount();
                    return value == null || value <= 0
                        ? 'Nominal harus lebih dari 0'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal'),
                  subtitle: Text(shortDateFormat.format(_date)),
                  trailing: const Icon(Icons.calendar_today),
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
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan'),
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
