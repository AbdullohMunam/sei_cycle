class InventoryLogbookAction {
  const InventoryLogbookAction({
    required this.itemKey,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.unit,
    required this.notes,
    this.moduleType,
    this.category,
    this.shouldCreateProductionResult = false,
    this.productName,
  });

  final String itemKey;
  final String itemName;
  final String type;
  final double quantity;
  final String unit;
  final String notes;
  final String? moduleType;
  final String? category;
  final bool shouldCreateProductionResult;
  final String? productName;

  bool get isOut => type == 'out';
  bool get isIn => type == 'in';
}

List<InventoryLogbookAction> mapLogbookDetailsToInventoryActions({
  required String moduleType,
  required Map<String, dynamic> details,
  required String logbookId,
}) {
  final actions = <InventoryLogbookAction>[];

  void add({
    required String key,
    required String itemKey,
    required String itemName,
    required String type,
    required String unit,
    required String category,
    bool production = false,
    String? productName,
  }) {
    final quantity = _quantity(details[key]);
    if (quantity == null) return;
    actions.add(
      InventoryLogbookAction(
        itemKey: itemKey,
        itemName: itemName,
        type: type,
        quantity: quantity,
        unit: unit,
        moduleType: moduleType,
        category: category,
        notes: 'Otomatis dari logbook $logbookId',
        shouldCreateProductionResult: production,
        productName: productName,
      ),
    );
  }

  switch (moduleType) {
    case 'ayam_kampung':
      add(
        key: 'dedak_padi_kg',
        itemKey: 'dedak_padi',
        itemName: 'Dedak Padi',
        type: 'out',
        unit: 'kg',
        category: 'pakan',
      );
      add(
        key: 'talas_pepaya_kg',
        itemKey: 'talas_pepaya',
        itemName: 'Talas & Pepaya',
        type: 'out',
        unit: 'kg',
        category: 'pakan',
      );
      add(
        key: 'maggot_segar_kg',
        itemKey: 'maggot_segar',
        itemName: 'Maggot Segar',
        type: 'out',
        unit: 'kg',
        category: 'pakan',
      );
      add(
        key: 'produksi_telur_hari_ini',
        itemKey: 'telur_ayam',
        itemName: 'Telur Ayam',
        type: 'in',
        unit: 'butir',
        category: 'hasil_panen',
        production: true,
        productName: 'Telur Ayam',
      );
    case 'maggot_bsf':
      final organicKey = details.containsKey('sampah_organik_kg')
          ? 'sampah_organik_kg'
          : 'volume_limbah_masuk_kg';
      add(
        key: organicKey,
        itemKey: 'sampah_organik',
        itemName: 'Sampah Organik',
        type: 'out',
        unit: 'kg',
        category: 'bahan_produksi',
      );
      final harvestKey = details.containsKey('panen_maggot_kg')
          ? 'panen_maggot_kg'
          : 'estimasi_panen_kg';
      add(
        key: harvestKey,
        itemKey: 'maggot_segar',
        itemName: 'Maggot Segar',
        type: 'in',
        unit: 'kg',
        category: 'pakan',
        production: true,
        productName: 'Maggot Segar',
      );
      add(
        key: 'media_bekas_maggot_kg',
        itemKey: 'media_bekas_maggot',
        itemName: 'Media Bekas Maggot',
        type: 'in',
        unit: 'kg',
        category: 'bahan_produksi',
      );
    case 'cacing_tanah':
      add(
        key: 'pakan_organik_kg',
        itemKey: 'pakan_organik',
        itemName: 'Pakan Organik',
        type: 'out',
        unit: 'kg',
        category: 'pakan',
      );
      add(
        key: 'media_cacing_kg',
        itemKey: 'media_cacing',
        itemName: 'Media Cacing',
        type: 'out',
        unit: 'kg',
        category: 'bahan_produksi',
      );
      add(
        key: 'panen_kascing_kg',
        itemKey: 'kascing',
        itemName: 'Kascing',
        type: 'in',
        unit: 'kg',
        category: 'pupuk',
        production: true,
        productName: 'Kascing',
      );
      add(
        key: 'kascing_cair_liter',
        itemKey: 'kascing_cair',
        itemName: 'Kascing Cair',
        type: 'in',
        unit: 'liter',
        category: 'pupuk',
        production: true,
        productName: 'Kascing Cair',
      );
    case 'tanaman':
      add(
        key: 'pupuk_kascing_cair_liter',
        itemKey: 'kascing_cair',
        itemName: 'Kascing Cair',
        type: 'out',
        unit: 'liter',
        category: 'pupuk',
      );
      add(
        key: 'pupuk_kascing_kg',
        itemKey: 'kascing',
        itemName: 'Kascing',
        type: 'out',
        unit: 'kg',
        category: 'pupuk',
      );
      final harvest = _plantHarvest(details);
      if (harvest != null) {
        add(
          key: 'hasil_panen_kg',
          itemKey: harvest.itemKey,
          itemName: harvest.productName,
          type: 'in',
          unit: 'kg',
          category: 'hasil_panen',
          production: true,
          productName: harvest.productName,
        );
      }
    case 'lele':
      add(
        key: 'pakan_lele_kg',
        itemKey: 'pakan_lele',
        itemName: 'Pakan Lele',
        type: 'out',
        unit: 'kg',
        category: 'pakan',
      );
      add(
        key: 'panen_lele_kg',
        itemKey: 'lele_panen',
        itemName: 'Lele Panen',
        type: 'in',
        unit: 'kg',
        category: 'hasil_panen',
        production: true,
        productName: 'Lele Panen',
      );
  }

  return actions;
}

({String itemKey, String productName})? _plantHarvest(
  Map<String, dynamic> details,
) {
  if (_quantity(details['hasil_panen_kg']) == null) return null;
  final crop = (details['jenis_tanaman'] ?? '').toString().toLowerCase();
  if (crop.contains('singkong')) {
    return (itemKey: 'hasil_singkong', productName: 'Singkong Panen');
  }
  if (crop.contains('kacang')) {
    return (
      itemKey: 'hasil_kacang_panjang',
      productName: 'Kacang Panjang Panen',
    );
  }
  if (crop.contains('pepaya')) {
    return (itemKey: 'hasil_pepaya', productName: 'Pepaya Panen');
  }
  if (crop.contains('talas')) {
    return (itemKey: 'hasil_talas', productName: 'Talas Panen');
  }
  return null;
}

double? _quantity(Object? value) {
  if (value is num && value > 0) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}
