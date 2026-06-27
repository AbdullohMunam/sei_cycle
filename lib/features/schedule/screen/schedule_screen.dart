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
import '../models/schedule_item.dart';
import '../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleService _service;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _service = ScheduleService();
  }

  Future<void> _openForm([ScheduleItem? item]) async {
    final value = await showDialog<_ScheduleFormValue>(
      context: context,
      builder: (_) => _ScheduleFormDialog(item: item),
    );
    if (value == null || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.save(
        id: item?.id,
        title: value.title,
        moduleId: value.moduleId,
        scheduleType: value.scheduleType,
        scheduledAt: value.scheduledAt,
        status: value.status,
        note: value.note,
        userId: widget.profile.uid,
      ),
      successMessage: item == null
          ? 'Jadwal ditambahkan.'
          : 'Jadwal diperbarui.',
    );
  }

  Future<void> _pickFilterDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _updateStatus(ScheduleItem item, String status) async {
    await runOperationWithFeedback(
      context,
      operation: () => _service.updateStatus(item.id, status),
      successMessage: 'Status jadwal diperbarui.',
    );
  }

  Future<void> _delete(ScheduleItem item) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus jadwal?',
      message: 'Agenda ${item.title} akan dihapus dari kalender operasional.',
    );
    if (!confirmed || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.delete(item.id),
      successMessage: 'Jadwal dihapus.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Kalender Operasional',
      subtitle: 'Jadwal pakan, perawatan, pemupukan, dan panen Kebun Sei.',
      actions: [
        if (widget.profile.canManageSchedules)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah jadwal'),
          ),
      ],
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: ResponsiveFormRow(
              breakpoint: 560,
              children: [
                Row(
                  children: [
                    const AppIconBox(
                      icon: Icons.calendar_month_outlined,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _date == null
                                ? 'Semua jadwal operasional'
                                : shortDateFormat.format(_date!),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _date == null
                                ? 'Pilih tanggal untuk melihat agenda tertentu.'
                                : 'Menampilkan agenda pada tanggal yang dipilih.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickFilterDate,
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(_date == null ? 'Pilih tanggal' : 'Ganti'),
                      ),
                    ),
                    if (_date != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => setState(() => _date = null),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Hapus filter tanggal',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<ScheduleItem>>(
              stream: _service.watchSchedules(date: _date),
              builder: (context, snapshot) {
                final state = asyncSnapshotState(snapshot);
                if (state != null) return state;
                final schedules = snapshot.requireData;
                if (schedules.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada agenda pada periode ini',
                    message:
                        'Jadwal akan muncul setelah pengingat operasional pertama dibuat.',
                    icon: Icons.event_note_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: schedules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ScheduleCard(
                    item: schedules[index],
                    canEdit: widget.profile.canManageSchedules,
                    canDelete: widget.profile.canDeleteSchedules,
                    onEdit: () => _openForm(schedules[index]),
                    onDelete: () => _delete(schedules[index]),
                    onStatusChanged: (status) =>
                        _updateStatus(schedules[index], status),
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.item,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final ScheduleItem item;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(icon: _statusIcon(item.status), color: color),
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
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: _statusLabel(item.status),
                      color: color,
                      icon: _statusIcon(item.status),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  dateTimeFormat.format(item.scheduledAt),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: FarmModules.nameOf(item.moduleId),
                      color: AppColors.primaryGreen,
                    ),
                    StatusBadge(
                      label: item.scheduleType,
                      color: AppColors.info,
                    ),
                  ],
                ),
                if (item.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Text(
                    item.note,
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
              tooltip: 'Opsi jadwal',
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                  return;
                }
                if (value == 'delete') {
                  onDelete();
                  return;
                }
                onStatusChanged(value);
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                if (canEdit) ...const [
                  PopupMenuItem(
                    value: 'pending',
                    child: Text('Tandai menunggu'),
                  ),
                  PopupMenuItem(value: 'done', child: Text('Tandai selesai')),
                  PopupMenuItem(
                    value: 'skipped',
                    child: Text('Tandai dilewati'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'edit', child: Text('Edit jadwal')),
                ],
                if (canEdit && canDelete) const PopupMenuDivider(),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus jadwal'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScheduleFormValue {
  const _ScheduleFormValue({
    required this.title,
    required this.moduleId,
    required this.scheduleType,
    required this.scheduledAt,
    required this.status,
    required this.note,
  });

  final String title;
  final String moduleId;
  final String scheduleType;
  final DateTime scheduledAt;
  final String status;
  final String note;
}

class _ScheduleFormDialog extends StatefulWidget {
  const _ScheduleFormDialog({this.item});

  final ScheduleItem? item;

  @override
  State<_ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<_ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _type;
  late final TextEditingController _note;
  late String _moduleId;
  late String _status;
  late DateTime _scheduledAt;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title);
    _type = TextEditingController(text: item?.scheduleType);
    _note = TextEditingController(text: item?.note);
    _moduleId = item?.moduleId ?? FarmModules.ayamKampung.id;
    _status = item?.status ?? 'pending';
    _scheduledAt = item?.scheduledAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _type.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _ScheduleFormValue(
        title: _title.text,
        moduleId: _moduleId,
        scheduleType: _type.text,
        scheduledAt: _scheduledAt,
        status: _status,
        note: _note.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Judul agenda',
                    hintText: 'Contoh: pakan lele sore',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
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
                  controller: _type,
                  decoration: const InputDecoration(
                    labelText: 'Jenis jadwal',
                    hintText: 'Pakan, perawatan, panen, atau lainnya',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppMenuCard(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Waktu pelaksanaan',
                  subtitle: dateTimeFormat.format(_scheduledAt),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Menunggu')),
                    DropdownMenuItem(value: 'done', child: Text('Selesai')),
                    DropdownMenuItem(value: 'skipped', child: Text('Dilewati')),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    hintText: 'Detail pelaksanaan atau kebutuhan (opsional)',
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

Color _statusColor(String status) => switch (status) {
  'done' => AppColors.success,
  'skipped' => AppColors.textMuted,
  _ => AppColors.warning,
};

IconData _statusIcon(String status) => switch (status) {
  'done' => Icons.check_circle_outline,
  'skipped' => Icons.skip_next_outlined,
  _ => Icons.schedule_outlined,
};

String _statusLabel(String status) => switch (status) {
  'done' => 'Selesai',
  'skipped' => 'Dilewati',
  _ => 'Menunggu',
};

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
