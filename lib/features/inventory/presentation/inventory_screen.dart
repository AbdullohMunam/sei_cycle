import 'package:flutter/material.dart';

import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../profile/models/app_user.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final InventoryService _service;

  @override
  void initState() {
    super.initState();
    _service = InventoryService();
  }

  Future<void> _openForm([InventoryItem? item]) async {
    final value = await showDialog<_InventoryFormValue>(
      context: context,
      builder: (_) => _InventoryFormDialog(item: item),
    );
    if (value == null) return;
    await _service.save(
      id: item?.id,
      name: value.name,
      category: value.category,
      unit: value.unit,
      currentStock: value.currentStock,
      minStock: value.minStock,
      userId: widget.profile.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Inventaris',
      subtitle: 'Pantau stok dan batas minimum kebutuhan Kebun Sei.',
      actions: [
        if (widget.profile.canManageOperations)
          FilledButton.icon(
            onPressed: _openForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah stok'),
          ),
      ],
      child: StreamBuilder<List<InventoryItem>>(
        stream: _service.watchItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingState();
          if (snapshot.hasError) {
            return ErrorState(message: '${snapshot.error}');
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Inventaris masih kosong',
              message: 'Tambahkan pakan, alat, benih, atau kebutuhan lainnya.',
              icon: Icons.inventory_2_outlined,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isLowStock
                        ? Colors.red.withValues(alpha: 0.12)
                        : Colors.green.withValues(alpha: 0.12),
                    foregroundColor: item.isLowStock
                        ? Colors.red
                        : Colors.green,
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    '${item.category} · Minimum ${_number(item.minStock)} '
                    '${item.unit}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          '${_number(item.currentStock)} ${item.unit}',
                        ),
                        avatar: Icon(
                          item.isLowStock
                              ? Icons.warning_amber
                              : Icons.check_circle_outline,
                          size: 18,
                          color: item.isLowStock ? Colors.red : Colors.green,
                        ),
                      ),
                      if (widget.profile.canManageOperations)
                        IconButton(
                          onPressed: () => _openForm(item),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit stok',
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InventoryFormValue {
  const _InventoryFormValue({
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minStock,
  });

  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minStock;
}

class _InventoryFormDialog extends StatefulWidget {
  const _InventoryFormDialog({this.item});

  final InventoryItem? item;

  @override
  State<_InventoryFormDialog> createState() => _InventoryFormDialogState();
}

class _InventoryFormDialogState extends State<_InventoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _unit;
  late final TextEditingController _currentStock;
  late final TextEditingController _minStock;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name);
    _category = TextEditingController(text: item?.category);
    _unit = TextEditingController(text: item?.unit);
    _currentStock = TextEditingController(
      text: item == null ? '' : _number(item.currentStock),
    );
    _minStock = TextEditingController(
      text: item == null ? '' : _number(item.minStock),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _unit.dispose();
    _currentStock.dispose();
    _minStock.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _InventoryFormValue(
        name: _name.text,
        category: _category.text,
        unit: _unit.text,
        currentStock: _parse(_currentStock.text)!,
        minStock: _parse(_minStock.text)!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Tambah Inventaris' : 'Edit Inventaris',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nama item'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(labelText: 'Satuan'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _currentStock,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Stok saat ini',
                        ),
                        validator: (value) => _parse(value ?? '') == null
                            ? 'Angka tidak valid'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _minStock,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Stok minimum',
                        ),
                        validator: (value) => _parse(value ?? '') == null
                            ? 'Angka tidak valid'
                            : null,
                      ),
                    ),
                  ],
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

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Wajib diisi' : null;
