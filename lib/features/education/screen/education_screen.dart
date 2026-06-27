import 'package:flutter/material.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/utils/delete_confirmation.dart';
import '../../../core/utils/operation_feedback.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../models/education_content.dart';
import '../services/education_service.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late final EducationService _service;
  String _query = '';
  String? _type;
  String? _moduleType;

  @override
  void initState() {
    super.initState();
    _service = EducationService();
  }

  Future<void> _openForm([EducationContent? content]) async {
    final value = await showDialog<_EducationFormValue>(
      context: context,
      builder: (_) => _EducationFormDialog(content: content),
    );
    if (value == null || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.save(
        id: content?.id,
        title: value.title,
        type: value.type,
        content: value.content,
        externalUrl: value.externalUrl,
        status: value.status,
        moduleType: value.moduleType,
        userId: widget.profile.uid,
      ),
      successMessage: content == null
          ? 'Konten ditambahkan.'
          : 'Konten diperbarui.',
    );
  }

  Future<void> _delete(EducationContent content) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus konten?',
      message: 'Konten ${content.title} akan dihapus dari materi edukasi.',
    );
    if (!confirmed || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.delete(content.id, userId: widget.profile.uid),
      successMessage: 'Konten dihapus.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Edukasi Kebun Sei',
      subtitle: 'Panduan lapangan, artikel, video, dan SOP untuk tim kebun.',
      actions: [
        if (widget.profile.canManageEducation)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah konten'),
          ),
      ],
      child: Column(
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: ResponsiveFormRow(
              breakpoint: 720,
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Cari judul atau isi panduan...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Jenis konten'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua jenis')),
                    for (final type in EducationType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(EducationType.label(type)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                ),
                DropdownButtonFormField<String?>(
                  initialValue: _moduleType,
                  decoration: const InputDecoration(labelText: 'Modul Kebun'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Modul')),
                    for (final module in FarmModules.values)
                      DropdownMenuItem(
                        value: module.id,
                        child: Text(module.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _moduleType = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<EducationContent>>(
              stream: _service.watchContents(
                includeDrafts: widget.profile.canManageEducation,
                type: _type,
                moduleType: _moduleType,
              ),
              builder: (context, snapshot) {
                final state = asyncSnapshotState(snapshot);
                if (state != null) return state;
                final query = _query.toLowerCase();
                final contents = snapshot.requireData.where((item) {
                  final matchesQuery =
                      query.isEmpty ||
                      item.title.toLowerCase().contains(query) ||
                      item.previewText.toLowerCase().contains(query);
                  return matchesQuery;
                }).toList();
                if (contents.isEmpty) {
                  return EmptyState(
                    title: _query.isEmpty && _type == null && _moduleType == null
                        ? 'Belum ada materi edukasi'
                        : 'Materi tidak ditemukan',
                    message: _query.isEmpty
                        ? 'Panduan akan muncul setelah admin menerbitkan konten pertama.'
                        : 'Coba gunakan kata kunci lain atau ubah filter pencarian.',
                    icon: Icons.school_outlined,
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 580
                        ? 2
                        : 1;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 250,
                      ),
                      itemCount: contents.length,
                      itemBuilder: (context, index) {
                        return _EducationCard(
                          content: contents[index],
                          canEdit: widget.profile.canManageEducation,
                          canDelete: widget.profile.canDeleteEducation,
                          onEdit: () => _openForm(contents[index]),
                          onDelete: () => _delete(contents[index]),
                        );
                      },
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

class _EducationCard extends StatelessWidget {
  const _EducationCard({
    required this.content,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final EducationContent content;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(content.type);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            color: color.withValues(alpha: 0.1),
            child: Row(
              children: [
                AppIconBox(icon: _iconForType(content.type), color: color),
                const SizedBox(width: 10),
                StatusBadge(label: EducationType.label(content.type), color: color),
                const Spacer(),
                if (content.status != EducationStatus.published)
                  StatusBadge(
                    label: EducationStatus.label(content.status),
                    color: content.status == EducationStatus.archived
                        ? AppColors.textMuted
                        : AppColors.warning,
                    icon: content.status == EducationStatus.archived
                        ? Icons.archive_outlined
                        : Icons.edit_note_outlined,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: Text(
                      content.previewText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (content.videoUrl.isNotEmpty) ...[
                        const Icon(
                          Icons.link_rounded,
                          size: 15,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'Tautan tersedia',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (content.moduleType.isNotEmpty) ...[
                        const Icon(
                          Icons.eco_outlined,
                          size: 15,
                          color: AppColors.accentBrown,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            FarmModules.nameOf(content.moduleType),
                            style: const TextStyle(
                              color: AppColors.accentBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (canEdit || canDelete)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit)
                              IconButton(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 19),
                                tooltip: 'Edit konten',
                              ),
                            if (canDelete)
                              IconButton(
                                onPressed: onDelete,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 19,
                                  color: AppColors.error,
                                ),
                                tooltip: 'Hapus konten',
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(String type) => switch (type) {
  EducationType.video => Icons.ondemand_video_outlined,
  EducationType.sop => Icons.fact_check_outlined,
  _ => Icons.article_outlined,
};

Color _colorForType(String type) => switch (type) {
  EducationType.video => AppColors.info,
  EducationType.sop => AppColors.accentBrown,
  _ => AppColors.primaryGreen,
};

class _EducationFormValue {
  const _EducationFormValue({
    required this.title,
    required this.type,
    required this.content,
    required this.externalUrl,
    required this.status,
    required this.moduleType,
  });

  final String title;
  final String type;
  final String content;
  final String externalUrl;
  final String status;
  final String moduleType;
}

class _EducationFormDialog extends StatefulWidget {
  const _EducationFormDialog({this.content});

  final EducationContent? content;

  @override
  State<_EducationFormDialog> createState() => _EducationFormDialogState();
}

class _EducationFormDialogState extends State<_EducationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _url;
  late String _type;
  late String _status;
  String? _moduleType;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.content?.title);
    
    // Reverse logic for content based on type for the simple form
    String initialContent = widget.content?.content ?? '';
    if (widget.content?.type == EducationType.sop && widget.content!.steps.isNotEmpty) {
      initialContent = widget.content!.steps.join('\n');
    }
    _content = TextEditingController(text: initialContent);
    _url = TextEditingController(text: widget.content?.videoUrl);
    _type = widget.content?.type ?? EducationType.article;
    _status = widget.content?.status ?? EducationStatus.draft;
    _moduleType = (widget.content?.moduleType.isNotEmpty ?? false) ? widget.content!.moduleType : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _url.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _EducationFormValue(
        title: _title.text,
        type: _type,
        content: _content.text,
        externalUrl: _url.text,
        status: _status,
        moduleType: _moduleType ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.content == null ? 'Tambah Edukasi' : 'Edit Edukasi'),
      content: SizedBox(
        width: 560,
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
                ResponsiveFormRow(
                  breakpoint: 400,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Tipe'),
                      items: [
                        for (final type in EducationType.values)
                          DropdownMenuItem(
                            value: type,
                            child: Text(EducationType.label(type)),
                          ),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: _moduleType,
                      decoration: const InputDecoration(labelText: 'Modul (Opsional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Umum')),
                        for (final module in FarmModules.values)
                          DropdownMenuItem(
                            value: module.id,
                            child: Text(module.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _moduleType = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _content,
                  maxLines: 7,
                  decoration: InputDecoration(
                    labelText: _type == EducationType.sop 
                      ? 'Langkah SOP (pisahkan dengan enter)' 
                      : 'Isi konten/deskripsi',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'External URL (Opsional untuk video)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status Publikasi'),
                  items: [
                    for (final status in EducationStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(EducationStatus.label(status)),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
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
