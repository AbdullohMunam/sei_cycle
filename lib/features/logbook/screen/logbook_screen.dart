import 'package:flutter/material.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/operation_feedback.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../theme/app_theme.dart';
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
    if (value == null || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.save(
        id: entry?.id,
        moduleId: value.moduleId,
        activityType: value.activityType,
        activityDate: value.activityDate,
        quantity: value.quantity,
        unit: value.unit,
        condition: value.condition,
        note: value.note,
        userId: widget.profile.uid,
      ),
      successMessage: entry == null
          ? 'Logbook ditambahkan.'
          : 'Logbook diperbarui.',
    );
  }

  Future<void> _delete(LogbookEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text(
          'Catatan akan disembunyikan dari logbook, tetapi tetap tersimpan sebagai arsip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await runOperationWithFeedback(
        context,
        operation: () => _service.softDelete(entry.id),
        successMessage: 'Logbook dihapus.',
      );
    }
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
      subtitle: 'Catatan harian Ayam, Maggot, Cacing, Lele, dan Tanaman.',
      actions: [
        if (widget.profile.canManageOperations)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah catatan'),
          ),
      ],
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: ResponsiveFormRow(
              breakpoint: 560,
              children: [
                DropdownButtonFormField<String?>(
                  initialValue: _moduleId,
                  decoration: const InputDecoration(labelText: 'Modul kebun'),
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
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _date == null
                        ? 'Semua tanggal'
                        : shortDateFormat.format(_date!),
                  ),
                ),
              ],
            ),
          ),
          if (_date != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _date = null),
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Hapus filter tanggal'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<LogbookEntry>>(
              stream: _service.watchEntries(moduleId: _moduleId, date: _date),
              builder: (context, snapshot) {
                final state = asyncSnapshotState(snapshot);
                if (state != null) return state;
                final entries = snapshot.requireData;
                if (entries.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada aktivitas pada filter ini',
                    message:
                        'Data akan muncul setelah pencatatan operasional pertama dibuat.',
                    icon: Icons.menu_book_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _LogbookEntryCard(
                    entry: entries[index],
                    canEdit: widget.profile.canManageOperations,
                    onEdit: () => _openForm(entries[index]),
                    onDelete: () => _delete(entries[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogbookEntryCard extends StatelessWidget {
  const _LogbookEntryCard({
    required this.entry,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final LogbookEntry entry;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor(entry.moduleId);
    final moduleName = FarmModules.nameOf(entry.moduleId);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(icon: _moduleIcon(entry.moduleId), color: color),
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
                        entry.activityType,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: moduleName, color: color),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      shortDateFormat.format(entry.activityDate),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: '${_number(entry.quantity)} ${entry.unit}',
                      color: AppColors.primaryGreen,
                      icon: Icons.straighten_outlined,
                    ),
                    StatusBadge(
                      label: entry.condition,
                      color: AppColors.info,
                      icon: Icons.health_and_safety_outlined,
                    ),
                  ],
                ),
                if (entry.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    entry.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              tooltip: 'Opsi catatan',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit catatan'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text('Hapus catatan'),
                  ),
                ),
              ],
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
                  decoration: const InputDecoration(labelText: 'Modul kebun'),
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
                    hintText: 'Contoh: pemberian pakan pagi',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppMenuCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Tanggal aktivitas',
                  subtitle: shortDateFormat.format(_activityDate),
                  trailing: const Icon(Icons.chevron_right_rounded),
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
                const SizedBox(height: 12),
                ResponsiveFormRow(
                  children: [
                    TextFormField(
                      controller: _quantity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Jumlah'),
                      validator: (value) {
                        final quantity = double.tryParse(
                          (value ?? '').replaceAll(',', '.'),
                        );
                        return quantity == null || quantity <= 0
                            ? 'Jumlah harus lebih dari 0'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        hintText: 'kg, liter, ekor',
                      ),
                      validator: _required,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _condition,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi',
                    hintText: 'Baik, perlu dipantau, atau lainnya',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Temuan atau tindak lanjut (opsional)',
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

Color _moduleColor(String moduleId) => switch (moduleId) {
  'ayam_kampung' => AppColors.warning,
  'maggot_bsf' => AppColors.accentBrown,
  'cacing_tanah' => AppColors.primaryGreen,
  'lele' => AppColors.info,
  'tanaman' => AppColors.success,
  _ => AppColors.textMuted,
};

IconData _moduleIcon(String moduleId) => switch (moduleId) {
  'ayam_kampung' => Icons.egg_alt_outlined,
  'maggot_bsf' => Icons.pest_control_outlined,
  'cacing_tanah' => Icons.grass_outlined,
  'lele' => Icons.water_drop_outlined,
  'tanaman' => Icons.eco_outlined,
  _ => Icons.category_outlined,
};

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi' : null;

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
