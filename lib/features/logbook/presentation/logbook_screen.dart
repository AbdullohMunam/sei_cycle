import 'package:flutter/material.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../profile/models/app_user.dart';
import '../models/logbook_entry.dart';
import '../services/logbook_service.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  late final LogbookService _service;
  String? _moduleId;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _service = LogbookService();
  }

  Future<void> _openForm([LogbookEntry? entry]) async {
    final value = await showDialog<_LogbookFormValue>(
      context: context,
      builder: (_) => _LogbookFormDialog(entry: entry),
    );
    if (value == null) return;
    await _service.save(
      id: entry?.id,
      moduleId: value.moduleId,
      activityType: value.activityType,
      activityDate: value.activityDate,
      quantity: value.quantity,
      unit: value.unit,
      condition: value.condition,
      note: value.note,
      userId: widget.profile.uid,
    );
  }

  Future<void> _delete(LogbookEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text(
          'Catatan akan disembunyikan dengan soft delete dan tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _service.softDelete(entry.id);
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Logbook Operasional',
      subtitle: 'Catatan Ayam, Maggot, Cacing, Lele, dan Tanaman.',
      actions: [
        if (widget.profile.canManageOperations)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah'),
          ),
      ],
      child: Column(
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: _moduleId,
                  decoration: const InputDecoration(labelText: 'Modul'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua modul'),
                    ),
                    for (final module in FarmModules.values)
                      DropdownMenuItem(
                        value: module.id,
                        child: Text(module.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _moduleId = value),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _date == null
                      ? 'Semua tanggal'
                      : shortDateFormat.format(_date!),
                ),
              ),
              if (_date != null)
                IconButton(
                  onPressed: () => setState(() => _date = null),
                  icon: const Icon(Icons.clear),
                  tooltip: 'Hapus filter tanggal',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<LogbookEntry>>(
              stream: _service.watchEntries(moduleId: _moduleId, date: _date),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LoadingState();
                if (snapshot.hasError) {
                  return ErrorState(message: '${snapshot.error}');
                }
                final entries = snapshot.data!;
                if (entries.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada logbook',
                    message: 'Tambahkan catatan operasional pertama.',
                    icon: Icons.menu_book_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            FarmModules.nameOf(entry.moduleId).substring(0, 1),
                          ),
                        ),
                        title: Text(entry.activityType),
                        subtitle: Text(
                          '${FarmModules.nameOf(entry.moduleId)} · '
                          '${shortDateFormat.format(entry.activityDate)}\n'
                          '${_number(entry.quantity)} ${entry.unit} · '
                          '${entry.condition}',
                        ),
                        isThreeLine: true,
                        trailing: widget.profile.canManageOperations
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _openForm(entry);
                                  if (value == 'delete') _delete(entry);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Soft delete'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogbookFormValue {
  const _LogbookFormValue({
    required this.moduleId,
    required this.activityType,
    required this.activityDate,
    required this.quantity,
    required this.unit,
    required this.condition,
    required this.note,
  });

  final String moduleId;
  final String activityType;
  final DateTime activityDate;
  final double quantity;
  final String unit;
  final String condition;
  final String note;
}

class _LogbookFormDialog extends StatefulWidget {
  const _LogbookFormDialog({this.entry});

  final LogbookEntry? entry;

  @override
  State<_LogbookFormDialog> createState() => _LogbookFormDialogState();
}

class _LogbookFormDialogState extends State<_LogbookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _moduleId;
  late DateTime _activityDate;
  late final TextEditingController _activityType;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _condition;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _moduleId = entry?.moduleId ?? FarmModules.ayamKampung.id;
    _activityDate = entry?.activityDate ?? DateTime.now();
    _activityType = TextEditingController(text: entry?.activityType);
    _quantity = TextEditingController(
      text: entry == null ? '' : _number(entry.quantity),
    );
    _unit = TextEditingController(text: entry?.unit);
    _condition = TextEditingController(text: entry?.condition);
    _note = TextEditingController(text: entry?.note);
  }

  @override
  void dispose() {
    _activityType.dispose();
    _quantity.dispose();
    _unit.dispose();
    _condition.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _LogbookFormValue(
        moduleId: _moduleId,
        activityType: _activityType.text,
        activityDate: _activityDate,
        quantity: double.parse(_quantity.text.replaceAll(',', '.')),
        unit: _unit.text,
        condition: _condition.text,
        note: _note.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry == null ? 'Tambah Logbook' : 'Edit Logbook'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _moduleId,
                  decoration: const InputDecoration(labelText: 'Modul'),
                  items: [
                    for (final module in FarmModules.values)
                      DropdownMenuItem(
                        value: module.id,
                        child: Text(module.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _moduleId = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _activityType,
                  decoration: const InputDecoration(
                    labelText: 'Jenis aktivitas',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal aktivitas'),
                  subtitle: Text(shortDateFormat.format(_activityDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _activityDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _activityDate = date);
                    }
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Jumlah'),
                        validator: (value) =>
                            double.tryParse(
                                  (value ?? '').replaceAll(',', '.'),
                                ) ==
                                null
                            ? 'Angka tidak valid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Satuan'),
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _condition,
                  decoration: const InputDecoration(labelText: 'Kondisi'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
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

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
