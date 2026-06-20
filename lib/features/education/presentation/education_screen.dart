import 'package:flutter/material.dart';

import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
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
    if (value == null) return;
    await _service.save(
      id: content?.id,
      title: value.title,
      type: value.type,
      content: value.content,
      externalUrl: value.externalUrl,
      isPublished: value.isPublished,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Edukasi Kebun Sei',
      subtitle: 'Artikel, video eksternal, dan SOP tanpa upload Storage.',
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Cari edukasi...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String?>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipe'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Semua')),
                    DropdownMenuItem(value: 'artikel', child: Text('Artikel')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'sop', child: Text('SOP')),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<EducationContent>>(
              stream: _service.watchContents(
                includeDrafts: widget.profile.isAdmin,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LoadingState();
                if (snapshot.hasError) {
                  return ErrorState(message: '${snapshot.error}');
                }
                final query = _query.toLowerCase();
                final contents = snapshot.data!.where((item) {
                  final matchesType = _type == null || item.type == _type;
                  final matchesQuery =
                      query.isEmpty ||
                      item.title.toLowerCase().contains(query) ||
                      item.content.toLowerCase().contains(query);
                  return matchesType && matchesQuery;
                }).toList();
                if (contents.isEmpty) {
                  return const EmptyState(
                    title: 'Konten tidak ditemukan',
                    message:
                        'Admin dapat menambahkan artikel, video, atau SOP.',
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
                        mainAxisExtent: 260,
                      ),
                      itemCount: contents.length,
                      itemBuilder: (context, index) {
                        final content = contents[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(_iconForType(content.type)),
                                    const SizedBox(width: 8),
                                    Chip(label: Text(content.type)),
                                    const Spacer(),
                                    if (!content.isPublished)
                                      const Chip(label: Text('Draft')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  content.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    content.content,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (content.externalUrl.isNotEmpty)
                                  SelectableText(
                                    content.externalUrl,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                if (widget.profile.isAdmin)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      onPressed: () => _openForm(content),
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit konten',
                                    ),
                                  ),
                              ],
                            ),
                          ),
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

IconData _iconForType(String type) => switch (type) {
  'video' => Icons.ondemand_video_outlined,
  'sop' => Icons.fact_check_outlined,
  _ => Icons.article_outlined,
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
