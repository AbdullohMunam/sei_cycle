import 'package:flutter/material.dart';

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
        isPublished: value.isPublished,
      ),
      successMessage: content == null
          ? 'Konten ditambahkan.'
          : 'Konten diperbarui.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Edukasi Kebun Sei',
      subtitle: 'Panduan lapangan, artikel, video, dan SOP untuk tim kebun.',
      actions: [
        if (widget.profile.isAdmin)
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
              breakpoint: 560,
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
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua jenis')),
                    DropdownMenuItem(value: 'artikel', child: Text('Artikel')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'sop', child: Text('SOP')),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<EducationContent>>(
              stream: _service.watchContents(
                includeDrafts: widget.profile.isAdmin,
              ),
              builder: (context, snapshot) {
                final state = asyncSnapshotState(snapshot);
                if (state != null) return state;
                final query = _query.toLowerCase();
                final contents = snapshot.requireData.where((item) {
                  final matchesType = _type == null || item.type == _type;
                  final matchesQuery =
                      query.isEmpty ||
                      item.title.toLowerCase().contains(query) ||
                      item.content.toLowerCase().contains(query);
                  return matchesType && matchesQuery;
                }).toList();
                if (contents.isEmpty) {
                  return EmptyState(
                    title: _query.isEmpty
                        ? 'Belum ada materi edukasi'
                        : 'Materi tidak ditemukan',
                    message: _query.isEmpty
                        ? 'Panduan akan muncul setelah admin menerbitkan konten pertama.'
                        : 'Coba gunakan kata kunci lain atau pilih semua jenis konten.',
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
                          canEdit: widget.profile.isAdmin,
                          onEdit: () => _openForm(contents[index]),
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
    required this.onEdit,
  });

  final EducationContent content;
  final bool canEdit;
  final VoidCallback onEdit;

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
                StatusBadge(label: _typeLabel(content.type), color: color),
                const Spacer(),
                if (!content.isPublished)
                  const StatusBadge(
                    label: 'Draft',
                    color: AppColors.warning,
                    icon: Icons.edit_note_outlined,
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
                      content.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (content.externalUrl.isNotEmpty) ...[
                        const Icon(
                          Icons.link_rounded,
                          size: 15,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 5),
                        const Expanded(
                          child: Text(
                            'Tautan pendukung tersedia',
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      if (canEdit)
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 19),
                          tooltip: 'Edit konten',
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
  'video' => Icons.ondemand_video_outlined,
  'sop' => Icons.fact_check_outlined,
  _ => Icons.article_outlined,
};

Color _colorForType(String type) => switch (type) {
  'video' => AppColors.info,
  'sop' => AppColors.accentBrown,
  _ => AppColors.primaryGreen,
};

String _typeLabel(String type) => switch (type) {
  'video' => 'Video',
  'sop' => 'SOP',
  _ => 'Artikel',
};

class _EducationFormValue {
  const _EducationFormValue({
    required this.title,
    required this.type,
    required this.content,
    required this.externalUrl,
    required this.isPublished,
  });

  final String title;
  final String type;
  final String content;
  final String externalUrl;
  final bool isPublished;
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
  late bool _published;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.content?.title);
    _content = TextEditingController(text: widget.content?.content);
    _url = TextEditingController(text: widget.content?.externalUrl);
    _type = widget.content?.type ?? 'artikel';
    _published = widget.content?.isPublished ?? true;
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
        isPublished: _published,
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
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                  items: const [
                    DropdownMenuItem(value: 'artikel', child: Text('Artikel')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'sop', child: Text('SOP')),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _content,
                  maxLines: 7,
                  decoration: const InputDecoration(labelText: 'Isi konten'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'External URL (opsional)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publikasikan'),
                  value: _published,
                  onChanged: (value) => setState(() => _published = value),
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
