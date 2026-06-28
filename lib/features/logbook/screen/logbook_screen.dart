import 'package:flutter/material.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/utils/delete_confirmation.dart';
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
  String? _moduleId = FarmModules.ayamKampung.id;
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
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus catatan?',
      message:
          'Catatan akan disembunyikan dari logbook, tetapi tetap tersimpan sebagai arsip.',
    );
    if (!confirmed || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () =>
          _service.softDelete(entry.id, userId: widget.profile.uid),
      successMessage: 'Logbook dihapus.',
    );
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
      subtitle: 'Catat aktivitas harian setiap modul budidaya',
      actions: [
        if (widget.profile.canManageLogbooks)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah catatan'),
          ),
      ],
      child: StreamBuilder<List<LogbookEntry>>(
        stream: _service.watchEntries(moduleId: _moduleId, date: _date),
        builder: (context, snapshot) {
          final state = asyncSnapshotState(snapshot);
          final entries = state == null ? snapshot.requireData : null;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _ModuleFilterBar(
                selectedModuleId: _moduleId,
                onSelected: (value) => setState(() => _moduleId = value),
              ),
              const SizedBox(height: 12),
              _ModuleHero(moduleId: _moduleId ?? FarmModules.ayamKampung.id),
              const SizedBox(height: 12),
              _DailyInputPanel(
                moduleId: _moduleId ?? '',
                date: _date,
                canManage: widget.profile.canManageLogbooks,
                onPickDate: _pickDate,
                onResetDate: () => setState(() => _date = null),
                onSave: _openForm,
              ),
              const SizedBox(height: 16),
              Text(
                'Riwayat Catatan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (state != null)
                SizedBox(height: 220, child: state)
              else if (entries!.isEmpty)
                const EmptyState(
                  title: 'Belum ada aktivitas pada filter ini',
                  message:
                      'Data akan muncul setelah pencatatan operasional pertama dibuat.',
                  icon: Icons.menu_book_outlined,
                )
              else
                for (var index = 0; index < entries.length; index++) ...[
                  _LogbookEntryCard(
                    entry: entries[index],
                    canEdit: widget.profile.canManageLogbooks,
                    canDelete: widget.profile.canDeleteLogbooks,
                    onEdit: () => _openForm(entries[index]),
                    onDelete: () => _delete(entries[index]),
                  ),
                  if (index < entries.length - 1) const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _LogbookEntryCard extends StatelessWidget {
  const _LogbookEntryCard({
    required this.entry,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final LogbookEntry entry;
  final bool canEdit;
  final bool canDelete;
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
          if (canEdit || canDelete)
            PopupMenuButton<String>(
              tooltip: 'Opsi catatan',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                if (canEdit)
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit catatan'),
                    ),
                  ),
                if (canEdit && canDelete) const PopupMenuDivider(),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
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

class _ModuleFilterBar extends StatelessWidget {
  const _ModuleFilterBar({
    required this.selectedModuleId,
    required this.onSelected,
  });

  final String? selectedModuleId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FarmModules.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final module = FarmModules.values[index];
          final selected = module.id == selectedModuleId;
          final color = _moduleColor(module.id);
          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              _moduleIcon(module.id),
              size: 16,
              color: selected ? Colors.white : color,
            ),
            label: Text('Modul ${module.name.split(' ').first}'),
            selectedColor: color,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => onSelected(module.id),
          );
        },
      ),
    );
  }
}

class _DailyInputPanel extends StatelessWidget {
  const _DailyInputPanel({
    required this.moduleId,
    required this.date,
    required this.canManage,
    required this.onPickDate,
    required this.onResetDate,
    required this.onSave,
  });

  final String moduleId;
  final DateTime? date;
  final bool canManage;
  final VoidCallback onPickDate;
  final VoidCallback onResetDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor(moduleId);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Input Harian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(
                  date == null ? 'Hari ini' : shortDateFormat.format(date!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReadonlyField(
            label: 'Modul Aktif',
            value: FarmModules.nameOf(moduleId),
            unit: 'aktif',
          ),
          const SizedBox(height: 8),
          _ReadonlyField(
            label: 'Filter Tanggal',
            value: date == null
                ? shortDateFormat.format(DateTime.now())
                : shortDateFormat.format(date!),
            unit: date == null ? 'hari ini' : 'filter',
          ),
          if (canManage || date != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (date != null)
                  OutlinedButton.icon(
                    onPressed: onResetDate,
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Reset'),
                  ),
                if (canManage)
                  FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Simpan Catatan'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ModuleHero extends StatelessWidget {
  const _ModuleHero({required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor(moduleId);
    final data = _moduleHeroData(moduleId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_moduleIcon(moduleId), color: Colors.white, size: 22),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var index = 0; index < data.stats.length; index++) ...[
                Expanded(
                  child: _HeroStat(
                    value: data.stats[index].$1,
                    label: data.stats[index].$2,
                  ),
                ),
                if (index < data.stats.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Positioned(
          left: 14,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.surface,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
      ],
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

({String title, String subtitle, List<(String, String)> stats}) _moduleHeroData(
  String moduleId,
) => switch (moduleId) {
  'ayam_kampung' => (
    title: 'Modul Ayam',
    subtitle: '150 ekor ayam kampung & petelur - Target 85+ telur/hari',
    stats: [
      ('150 ekor', 'Populasi'),
      ('88 butir', 'Produksi Kemarin'),
      ('85 butir', 'Target Harian'),
    ],
  ),
  'maggot_bsf' => (
    title: 'Modul Maggot BSF',
    subtitle: 'Pengolahan limbah organik menjadi pakan bernutrisi',
    stats: [
      ('50 kg', 'Media'),
      ('12 hari', 'Umur Batch'),
      ('18 kg', 'Estimasi Panen'),
    ],
  ),
  'cacing_tanah' => (
    title: 'Modul Cacing',
    subtitle: 'Produksi kascing dan pupuk cair untuk tanaman pangan',
    stats: [('100 rak', 'Unit Media'), ('72%', 'Lembap'), ('15 kg', 'Kascing')],
  ),
  'tanaman' => (
    title: 'Modul Tanaman Pangan Organik',
    subtitle: 'Talas - Singkong - Kacang Panjang - Pepaya - 500 m2 lahan',
    stats: [
      ('4 jenis', 'Komoditas'),
      ('+200 m2', 'Luas Lahan'),
      ('Kascing', 'Pupuk'),
    ],
  ),
  'lele' => (
    title: 'Modul Lele',
    subtitle: 'Kolam bioflok dengan pakan alternatif maggot segar',
    stats: [
      ('800 ekor', 'Populasi'),
      ('89%', 'Survival Rate'),
      ('2,5 kg', 'Pakan Pagi'),
    ],
  ),
  _ => (
    title: 'Modul Kebun',
    subtitle: 'Catatan operasional harian setiap modul budidaya',
    stats: [('Aktif', 'Status'), ('Hari ini', 'Tanggal'), ('Logbook', 'Mode')],
  ),
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
