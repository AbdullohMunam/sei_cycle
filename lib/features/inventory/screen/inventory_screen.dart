import 'package:flutter/material.dart';

import '../../../core/utils/operation_feedback.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../theme/app_theme.dart';
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
    if (value == null || !mounted) return;
    await runOperationWithFeedback(
      context,
      operation: () => _service.save(
        id: item?.id,
        name: value.name,
        category: value.category,
        unit: value.unit,
        currentStock: value.currentStock,
        minStock: value.minStock,
        userId: widget.profile.uid,
      ),
      successMessage: item == null
          ? 'Inventaris ditambahkan.'
          : 'Inventaris diperbarui.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'Inventaris',
      subtitle: 'Pantau pakan, alat, benih, dan kebutuhan rutin Kebun Sei.',
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
          final state = asyncSnapshotState(snapshot);
          if (state != null) return state;
          final items = snapshot.requireData;
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Inventaris masih kosong',
              message:
                  'Data akan muncul setelah pakan, alat, benih, atau kebutuhan pertama dicatat.',
              icon: Icons.inventory_2_outlined,
            );
          }

          final lowStockCount = items.where((item) => item.isLowStock).length;
          return Column(
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _SummaryItem(
                      icon: Icons.inventory_2_outlined,
                      label: '${items.length} jenis inventaris',
                      color: AppColors.primaryGreen,
                    ),
                    _SummaryItem(
                      icon: lowStockCount == 0
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      label: lowStockCount == 0
                          ? 'Stok dalam kondisi aman'
                          : '$lowStockCount item perlu perhatian',
                      color: lowStockCount == 0
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _InventoryItemCard(
                    item: items[index],
                    canEdit: widget.profile.canManageOperations,
                    onEdit: () => _openForm(items[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.item,
    required this.canEdit,
    required this.onEdit,
  });

  final InventoryItem item;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = item.isLowStock ? AppColors.warning : AppColors.success;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(icon: Icons.inventory_2_outlined, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.category,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: item.isLowStock ? 'Stok menipis' : 'Stok aman',
                      color: color,
                      icon: item.isLowStock
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_number(item.currentStock)} ${item.unit}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(color: color),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Batas minimum ${_number(item.minStock)} ${item.unit}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (canEdit)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        tooltip: 'Edit stok',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
                  decoration: const InputDecoration(
                    labelText: 'Nama item',
                    hintText: 'Contoh: pakan lele',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Pakan, alat, benih, atau lainnya',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    hintText: 'kg, liter, pcs, karung',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                ResponsiveFormRow(
                  children: [
                    TextFormField(
                      controller: _currentStock,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Stok saat ini',
                      ),
                      validator: (value) {
                        final stock = _parse(value ?? '');
                        return stock == null || stock < 0
                            ? 'Stok tidak boleh negatif'
                            : null;
                      },
                    ),
                    TextFormField(
                      controller: _minStock,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Stok minimum',
                      ),
                      validator: (value) {
                        final stock = _parse(value ?? '');
                        return stock == null || stock < 0
                            ? 'Stok tidak boleh negatif'
                            : null;
                      },
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
