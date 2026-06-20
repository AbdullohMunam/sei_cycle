import 'package:flutter/material.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
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
    if (value == null) return;
    await _service.save(
      id: item?.id,
      title: value.title,
      moduleId: value.moduleId,
      scheduleType: value.scheduleType,
      scheduledAt: value.scheduledAt,
      status: value.status,
      note: value.note,
      userId: widget.profile.uid,
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

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Kalender Operasional',
      subtitle: 'Jadwal pakan, perawatan, pemupukan, dan panen.',
      actions: [
        if (widget.profile.canManageOperations)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah jadwal'),
          ),
      ],
      child: Column(
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickFilterDate,
                icon: const Icon(Icons.calendar_today),
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
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<ScheduleItem>>(
              stream: _service.watchSchedules(date: _date),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LoadingState();
                if (snapshot.hasError) {
                  return ErrorState(message: '${snapshot.error}');
                }
                final schedules = snapshot.data!;
                if (schedules.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada jadwal',
                    message: 'Tambahkan pengingat operasional Kebun Sei.',
                    icon: Icons.event_note_outlined,
                  );
                }
                return ListView.separated(
                  itemCount: schedules.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = schedules[index];
                    return Card(
                      child: ListTile(
                        leading: _StatusIcon(status: item.status),
                        title: Text(item.title),
                        subtitle: Text(
                          '${FarmModules.nameOf(item.moduleId)} · '
                          '${dateTimeFormat.format(item.scheduledAt)}\n'
                          '${item.scheduleType} · ${item.note}',
                        ),
                        isThreeLine: true,
                        trailing: widget.profile.canManageOperations
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openForm(item);
                                  } else {
                                    _service.updateStatus(item.id, value);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'pending',
                                    child: Text('Tandai pending'),
                                  ),
                                  PopupMenuItem(
                                    value: 'done',
                                    child: Text('Tandai selesai'),
                                  ),
                                  PopupMenuItem(
                                    value: 'skipped',
                                    child: Text('Tandai dilewati'),
                                  ),
                                  PopupMenuDivider(),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                ],
                              )
                            : Chip(label: Text(item.status)),
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

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'done' => (Icons.check_circle, Colors.green),
      'skipped' => (Icons.skip_next, Colors.grey),
      _ => (Icons.schedule, Colors.orange),
    };
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.12),
      foregroundColor: color,
      child: Icon(icon),
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
                  decoration: const InputDecoration(labelText: 'Judul'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
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
                  controller: _type,
                  decoration: const InputDecoration(labelText: 'Jenis jadwal'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Waktu pelaksanaan'),
                  subtitle: Text(dateTimeFormat.format(_scheduledAt)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: _pickDateTime,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'done', child: Text('Selesai')),
                    DropdownMenuItem(value: 'skipped', child: Text('Dilewati')),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
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
