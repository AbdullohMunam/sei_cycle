import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_roles.dart';
import '../constants/firestore_collections.dart';
import '../../features/circular_flow/services/circular_flow_service.dart';

class SampleDataService {
  SampleDataService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const sampleVersion = 'v2';
  static const sampleCreatedBy = 'sample_seed';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> seedSampleData() async {
    final context = await _requireAdmin();
    final now = DateTime.now();
    final batch = _firestore.batch();
    var hasWrites = false;

    for (final document in _sampleDocuments(now, context.userId)) {
      final reference = _doc(document.collection, document.id);
      final existing = await reference.get();
      if (existing.exists) continue;

      batch.set(reference, document.data);
      hasWrites = true;
    }

    if (hasWrites) {
      await batch.commit();
    }
  }

  Future<bool> hasSampleData() async {
    await _requireAdmin();
    for (final document in _representativeDocuments) {
      final snapshot = await _doc(document.collection, document.id).get();
      final data = snapshot.data();
      if (!snapshot.exists ||
          data?['isSampleData'] != true ||
          data?['sampleVersion'] != sampleVersion) {
        return false;
      }
    }
    return true;
  }

  Future<void> clearSampleData() async {
    await _requireAdmin();
    for (final collection in _sampleCollections) {
      await _deleteSampleDocuments(collection);
    }
  }

  Future<_SampleSeedContext> _requireAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Seeder data sampel hanya bisa dijalankan setelah login.',
      );
    }

    final profile = await _doc(FirestoreCollections.users, user.uid).get();
    final data = profile.data();
    if (!profile.exists || data == null) {
      throw StateError('Profil admin belum ditemukan di collection users.');
    }

    final isActive = data['isActive'] != false && data['is_active'] != false;
    final role = AppRoles.effectiveRole(data['role']?.toString());
    if (!isActive || role != AppRoles.admin) {
      throw StateError(
        'Seeder data sampel hanya bisa dijalankan oleh admin aktif.',
      );
    }

    return _SampleSeedContext(userId: user.uid);
  }

  Future<void> _deleteSampleDocuments(String collection) async {
    while (true) {
      final snapshot = await _firestore
          .collection(collection)
          .where('isSampleData', isEqualTo: true)
          .limit(100)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>> _doc(String collection, String id) {
    return _firestore.collection(collection).doc(id);
  }
}

List<_SampleDocument> _sampleDocuments(DateTime now, String currentUserId) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    ..._sampleUsers(),
    ..._sampleFarmModules(),
    ..._sampleLogbooks(today),
    ..._sampleInventory(),
    ..._sampleInventoryTransactions(today),
    ..._sampleProductionResults(today),
    ..._sampleCircularFlows(now),
    ..._sampleSchedules(today),
    ..._sampleNotifications(today, currentUserId),
    ..._sampleEducation(),
    ..._sampleFinance(today),
    ..._sampleRecommendations(today),
  ];
}

List<_SampleDocument> _sampleUsers() {
  return [
    _sampleDoc(FirestoreCollections.users, 'sample_user_admin', {
      'uid': 'sample_user_admin',
      'name': 'Admin Kebun Sei',
      'email': 'admin.demo@seicycle.local',
      'photoUrl': '',
      'role': AppRoles.admin,
      'isActive': true,
    }),
    _sampleDoc(FirestoreCollections.users, 'sample_user_operator_lapangan', {
      'uid': 'sample_user_operator_lapangan',
      'name': 'Operator Lapangan',
      'email': 'lapangan.demo@seicycle.local',
      'photoUrl': '',
      'role': AppRoles.operatorLapangan,
      'isActive': true,
    }),
    _sampleDoc(FirestoreCollections.users, 'sample_user_operator_keuangan', {
      'uid': 'sample_user_operator_keuangan',
      'name': 'Operator Keuangan',
      'email': 'keuangan.demo@seicycle.local',
      'photoUrl': '',
      'role': AppRoles.operatorKeuangan,
      'isActive': true,
    }),
  ];
}

List<_SampleDocument> _sampleFarmModules() {
  final items = [
    (
      'ayam_kampung',
      'Modul Ayam',
      'peternakan',
      'Pencatatan ayam kampung dan produksi telur',
      'egg',
      '#F59E0B',
      1,
    ),
    (
      'maggot_bsf',
      'Modul Maggot',
      'budidaya',
      'Pengolahan sampah organik dengan maggot BSF',
      'bug_report',
      '#84CC16',
      2,
    ),
    (
      'cacing_tanah',
      'Modul Cacing',
      'budidaya',
      'Produksi kascing dan kascing cair',
      'grass',
      '#16A34A',
      3,
    ),
    (
      'tanaman',
      'Modul Tanaman',
      'pertanian',
      'Budidaya tanaman pangan organik',
      'eco',
      '#22C55E',
      4,
    ),
    (
      'lele',
      'Modul Lele',
      'perikanan',
      'Budidaya lele terintegrasi',
      'water_drop',
      '#0EA5E9',
      5,
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.farmModules, item.$1, {
        'name': item.$2,
        'type': item.$3,
        'description': item.$4,
        'icon': item.$5,
        'color': item.$6,
        'isActive': true,
        'order': item.$7,
      }),
  ];
}

List<_SampleDocument> _sampleLogbooks(DateTime today) {
  final items = [
    (
      'sample_logbook_ayam_001',
      'ayam_kampung',
      'Pemberian pakan pagi ayam kampung',
      today,
      2.0,
      'kg',
      'completed',
      'Pakan diberikan 2 kg, kondisi ayam aktif dan sehat.',
    ),
    (
      'sample_logbook_ayam_002',
      'ayam_kampung',
      'Pembersihan kandang ayam',
      today.subtract(const Duration(days: 1)),
      1.0,
      'kandang',
      'completed',
      'Kandang dibersihkan dan alas diganti agar tetap kering.',
    ),
    (
      'sample_logbook_ayam_003',
      'ayam_kampung',
      'Pengecekan produksi telur',
      today.subtract(const Duration(days: 3)),
      18.0,
      'butir',
      'completed',
      'Produksi telur stabil dan tidak ditemukan telur retak.',
    ),
    (
      'sample_logbook_maggot_001',
      'maggot_bsf',
      'Pengecekan media maggot',
      today.subtract(const Duration(days: 1)),
      5.0,
      'kg',
      'completed',
      'Media organik masih cukup lembap, larva aktif.',
    ),
    (
      'sample_logbook_maggot_002',
      'maggot_bsf',
      'Penambahan limbah organik maggot',
      today.subtract(const Duration(days: 4)),
      12.0,
      'kg',
      'completed',
      'Limbah sayur ditambahkan bertahap agar media tidak terlalu basah.',
    ),
    (
      'sample_logbook_maggot_003',
      'maggot_bsf',
      'Panen maggot segar',
      today.subtract(const Duration(days: 7)),
      4.5,
      'kg',
      'completed',
      'Sebagian maggot dipanen untuk pakan lele dan ayam.',
    ),
    (
      'sample_logbook_cacing_001',
      'cacing_tanah',
      'Pengecekan kelembapan media cacing',
      today.subtract(const Duration(days: 2)),
      1.0,
      'bedeng',
      'completed',
      'Media cukup lembap dan tidak berbau menyengat.',
    ),
    (
      'sample_logbook_cacing_002',
      'cacing_tanah',
      'Penambahan kompos matang',
      today.subtract(const Duration(days: 6)),
      8.0,
      'kg',
      'completed',
      'Kompos matang ditambahkan tipis di permukaan media.',
    ),
    (
      'sample_logbook_cacing_003',
      'cacing_tanah',
      'Panen kascing awal',
      today.subtract(const Duration(days: 10)),
      15.0,
      'kg',
      'completed',
      'Kascing diayak dan disimpan untuk pemupukan tanaman.',
    ),
    (
      'sample_logbook_lele_001',
      'lele',
      'Pemberian pakan lele pagi',
      today,
      3.0,
      'kg',
      'completed',
      'Respon makan lele baik, air kolam terlihat normal.',
    ),
    (
      'sample_logbook_lele_002',
      'lele',
      'Pengecekan kolam lele',
      today.subtract(const Duration(days: 1)),
      1.0,
      'kolam',
      'completed',
      'Sirkulasi air berjalan dan tidak ada tanda ikan stres.',
    ),
    (
      'sample_logbook_lele_003',
      'lele',
      'Sampling bobot lele',
      today.subtract(const Duration(days: 5)),
      180.0,
      'gram',
      'completed',
      'Bobot rata-rata meningkat sesuai target mingguan.',
    ),
    (
      'sample_logbook_tanaman_001',
      'tanaman',
      'Penyiraman tanaman pagi',
      today,
      1.0,
      'area',
      'completed',
      'Tanaman disiram merata dan daun terlihat segar.',
    ),
    (
      'sample_logbook_tanaman_002',
      'tanaman',
      'Pemupukan sayur daun',
      today.subtract(const Duration(days: 3)),
      6.0,
      'kg',
      'completed',
      'Kompos diberikan di pangkal tanaman sesuai takaran.',
    ),
    (
      'sample_logbook_tanaman_003',
      'tanaman',
      'Panen sayur daun',
      today.subtract(const Duration(days: 8)),
      22.0,
      'ikat',
      'completed',
      'Sayur dipanen pagi hari dan langsung disortir.',
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.logbooks, item.$1, {
        'title': item.$3,
        'moduleType': item.$2,
        'activityDate': Timestamp.fromDate(item.$4),
        'activityType': _activityTypeForLogbookTitle(item.$3),
        'quantity': item.$5,
        'unit': item.$6,
        'status': item.$7,
        'notes': item.$8,
        'details': _sampleLogbookDetails(item.$2, item.$3, item.$5),
        'updatedBy': SampleDataService.sampleCreatedBy,
        'isDeleted': false,
      }),
  ];
}

String _activityTypeForLogbookTitle(String title) {
  final value = title.toLowerCase();
  if (value.contains('panen') || value.contains('produksi')) return 'harvest';
  if (value.contains('pakan')) return 'feeding';
  if (value.contains('pembersihan') || value.contains('sanitasi')) {
    return 'maintenance';
  }
  if (value.contains('pemupukan') || value.contains('penyiraman')) {
    return 'cultivation';
  }
  return 'inspection';
}

Map<String, dynamic> _sampleLogbookDetails(
  String moduleType,
  String title,
  double quantity,
) {
  final lowerTitle = title.toLowerCase();
  return switch (moduleType) {
    'ayam_kampung' => {
      'populasi_aktif': 150,
      'konsumsi_pakan_g_per_ekor': 55,
      'produksi_telur_hari_ini': lowerTitle.contains('telur') ? quantity : 12,
      'berat_rata_rata_telur': 45,
      'mortalitas_hari_ini': 0,
      'dedak_padi_kg': lowerTitle.contains('pakan') ? quantity : 1.5,
      'talas_pepaya_kg': 1,
      'maggot_segar_kg': 0.5,
      'total_biaya_pakan': 35000,
      'kondisi_kandang': 'Kering dan bersih',
      'suhu_kandang': 28,
      'gejala_penyakit': 'Tidak ada',
    },
    'maggot_bsf' => {
      'volume_limbah_masuk_kg': lowerTitle.contains('limbah') ? quantity : 8,
      'sampah_organik_kg': lowerTitle.contains('limbah') ? quantity : 8,
      'panen_maggot_kg': lowerTitle.contains('panen') ? quantity : 0,
      'media_bekas_maggot_kg': lowerTitle.contains('panen') ? 4 : 0,
      'kondisi_media': 'Lembap normal',
      'bau_media': 'Normal',
      'umur_batch_hari': 12,
      'estimasi_panen_kg': lowerTitle.contains('panen') ? quantity : 3,
    },
    'cacing_tanah' => {
      'pakan_organik_kg': lowerTitle.contains('kompos') ? quantity : 3,
      'media_cacing_kg': 2,
      'panen_kascing_kg': lowerTitle.contains('panen') ? quantity : 0,
      'kascing_cair_liter': lowerTitle.contains('panen') ? 5 : 0,
      'kelembapan_media': 'Cukup',
      'kondisi_cacing': 'Aktif',
    },
    'tanaman' => {
      'jenis_tanaman': lowerTitle.contains('panen') ? 'Talas' : 'Sayur daun',
      'luas_area_m2': 80,
      'pupuk_kascing_kg': lowerTitle.contains('pemupukan') ? quantity : 2,
      'pupuk_kascing_cair_liter': lowerTitle.contains('penyiraman') ? 3 : 1,
      'hasil_panen_kg': lowerTitle.contains('panen') ? quantity : 0,
      'kondisi_tanaman': 'Sehat',
      'hama_penyakit': 'Tidak ada',
    },
    'lele' => {
      'jumlah_ikan': 450,
      'pakan_lele_kg': lowerTitle.contains('pakan') ? quantity : 2,
      'panen_lele_kg': lowerTitle.contains('panen') ? quantity : 0,
      'ph_air': 7.2,
      'suhu_air': 27,
      'kondisi_air': 'Normal',
      'mortalitas_hari_ini': 0,
    },
    _ => const <String, dynamic>{},
  };
}

List<_SampleDocument> _sampleInventory() {
  final items = [
    (
      'sample_inventory_dedak_padi',
      'Dedak Padi',
      'dedak_padi',
      'pakan',
      'kg',
      100.0,
      20.0,
    ),
    (
      'sample_inventory_talas_pepaya',
      'Talas & Pepaya',
      'talas_pepaya',
      'pakan',
      'kg',
      50.0,
      10.0,
    ),
    (
      'sample_inventory_maggot_segar',
      'Maggot Segar',
      'maggot_segar',
      'pakan',
      'kg',
      30.0,
      5.0,
    ),
    (
      'sample_inventory_telur_ayam',
      'Telur Ayam',
      'telur_ayam',
      'hasil_panen',
      'butir',
      0.0,
      0.0,
    ),
    (
      'sample_inventory_sampah_organik',
      'Sampah Organik',
      'sampah_organik',
      'bahan_produksi',
      'kg',
      100.0,
      20.0,
    ),
    (
      'sample_inventory_media_bekas_maggot',
      'Media Bekas Maggot',
      'media_bekas_maggot',
      'bahan_produksi',
      'kg',
      0.0,
      0.0,
    ),
    (
      'sample_inventory_pakan_organik',
      'Pakan Organik',
      'pakan_organik',
      'pakan',
      'kg',
      80.0,
      15.0,
    ),
    (
      'sample_inventory_media_cacing',
      'Media Cacing',
      'media_cacing',
      'bahan_produksi',
      'kg',
      60.0,
      10.0,
    ),
    (
      'sample_inventory_kascing',
      'Kascing',
      'kascing',
      'pupuk',
      'kg',
      20.0,
      5.0,
    ),
    (
      'sample_inventory_kascing_cair',
      'Kascing Cair',
      'kascing_cair',
      'pupuk',
      'liter',
      30.0,
      5.0,
    ),
    (
      'sample_inventory_pakan_lele',
      'Pakan Lele',
      'pakan_lele',
      'pakan',
      'kg',
      100.0,
      20.0,
    ),
    (
      'sample_inventory_lele_panen',
      'Lele Panen',
      'lele_panen',
      'hasil_panen',
      'kg',
      0.0,
      0.0,
    ),
    (
      'sample_inventory_hasil_talas',
      'Talas Panen',
      'hasil_talas',
      'hasil_panen',
      'kg',
      0.0,
      0.0,
    ),
    (
      'sample_inventory_hasil_singkong',
      'Singkong Panen',
      'hasil_singkong',
      'hasil_panen',
      'kg',
      0.0,
      0.0,
    ),
    (
      'sample_inventory_hasil_kacang_panjang',
      'Kacang Panjang Panen',
      'hasil_kacang_panjang',
      'hasil_panen',
      'kg',
      0.0,
      0.0,
    ),
    (
      'sample_inventory_hasil_pepaya',
      'Pepaya Panen',
      'hasil_pepaya',
      'hasil_panen',
      'kg',
      0.0,
      0.0,
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.inventory, item.$1, {
        'name': item.$2,
        'itemKey': item.$3,
        'moduleType': '',
        'category': item.$4,
        'unit': item.$5,
        'currentStock': item.$6,
        'minStock': item.$7,
        'isLowStock': item.$6 <= item.$7,
        'location': '',
        'updatedBy': SampleDataService.sampleCreatedBy,
        'isDeleted': false,
      }),
  ];
}

List<_SampleDocument> _sampleInventoryTransactions(DateTime today) {
  final items = [
    (
      'sample_inventory_txn_ayam_dedak',
      'sample_inventory_dedak_padi',
      'Dedak Padi',
      'dedak_padi',
      'ayam_kampung',
      'sample_logbook_ayam_001',
      'out',
      2.0,
      'kg',
      102.0,
      100.0,
      today.add(const Duration(hours: 7)),
    ),
    (
      'sample_inventory_txn_ayam_telur',
      'sample_inventory_telur_ayam',
      'Telur Ayam',
      'telur_ayam',
      'ayam_kampung',
      'sample_logbook_ayam_003',
      'in',
      18.0,
      'butir',
      0.0,
      18.0,
      today.subtract(const Duration(days: 3)).add(const Duration(hours: 8)),
    ),
    (
      'sample_inventory_txn_maggot_sampah',
      'sample_inventory_sampah_organik',
      'Sampah Organik',
      'sampah_organik',
      'maggot_bsf',
      'sample_logbook_maggot_002',
      'out',
      12.0,
      'kg',
      112.0,
      100.0,
      today.subtract(const Duration(days: 4)).add(const Duration(hours: 9)),
    ),
    (
      'sample_inventory_txn_maggot_panen',
      'sample_inventory_maggot_segar',
      'Maggot Segar',
      'maggot_segar',
      'maggot_bsf',
      'sample_logbook_maggot_003',
      'in',
      4.5,
      'kg',
      25.5,
      30.0,
      today.subtract(const Duration(days: 7)).add(const Duration(hours: 10)),
    ),
    (
      'sample_inventory_txn_kascing',
      'sample_inventory_kascing',
      'Kascing',
      'kascing',
      'cacing_tanah',
      'sample_logbook_cacing_003',
      'in',
      15.0,
      'kg',
      5.0,
      20.0,
      today.subtract(const Duration(days: 10)).add(const Duration(hours: 8)),
    ),
    (
      'sample_inventory_txn_lele_pakan',
      'sample_inventory_pakan_lele',
      'Pakan Lele',
      'pakan_lele',
      'lele',
      'sample_logbook_lele_001',
      'out',
      3.0,
      'kg',
      103.0,
      100.0,
      today.add(const Duration(hours: 7)),
    ),
    (
      'sample_inventory_txn_tanaman_pupuk',
      'sample_inventory_kascing',
      'Kascing',
      'kascing',
      'tanaman',
      'sample_logbook_tanaman_002',
      'out',
      6.0,
      'kg',
      26.0,
      20.0,
      today.subtract(const Duration(days: 3)).add(const Duration(hours: 8)),
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.inventoryTransactions, item.$1, {
        'itemId': item.$2,
        'itemName': item.$3,
        'itemKey': item.$4,
        'moduleType': item.$5,
        'logbookId': item.$6,
        'type': item.$7,
        'quantity': item.$8,
        'unit': item.$9,
        'beforeStock': item.$10,
        'afterStock': item.$11,
        'notes': 'Transaksi stok sample dari logbook.',
        'transactionDate': Timestamp.fromDate(item.$12),
        'isReversed': false,
        'reversedAt': null,
        'reversedBy': '',
      }),
  ];
}

List<_SampleDocument> _sampleProductionResults(DateTime today) {
  final items = [
    (
      'sample_production_telur_ayam',
      'sample_logbook_ayam_003',
      'ayam_kampung',
      'Telur Ayam',
      85.0,
      'butir',
      today.subtract(const Duration(days: 1)),
      'Telur bersih dan layak jual.',
    ),
    (
      'sample_production_maggot_segar',
      'sample_logbook_maggot_003',
      'maggot_bsf',
      'Maggot Segar',
      18.0,
      'kg',
      today.subtract(const Duration(days: 2)),
      'Maggot aktif, sebagian dialokasikan untuk pakan.',
    ),
    (
      'sample_production_kascing',
      'sample_logbook_cacing_003',
      'cacing_tanah',
      'Kascing',
      20.0,
      'kg',
      today.subtract(const Duration(days: 3)),
      'Kascing halus setelah ayak.',
    ),
    (
      'sample_production_kascing_cair',
      'sample_logbook_cacing_003',
      'cacing_tanah',
      'Kascing Cair',
      10.0,
      'liter',
      today.subtract(const Duration(days: 3)),
      'Kascing cair siap pakai untuk tanaman.',
    ),
    (
      'sample_production_lele_panen',
      'sample_logbook_lele_003',
      'lele',
      'Lele Panen',
      30.0,
      'kg',
      today.subtract(const Duration(days: 4)),
      'Ukuran konsumsi dan siap distribusi.',
    ),
    (
      'sample_production_talas_panen',
      'sample_logbook_tanaman_003',
      'tanaman',
      'Talas Panen',
      50.0,
      'kg',
      today.subtract(const Duration(days: 5)),
      'Talas disortir dari area tanaman pangan.',
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.productionResults, item.$1, {
        'logbookId': item.$2,
        'moduleType': item.$3,
        'productName': item.$4,
        'quantity': item.$5,
        'unit': item.$6,
        'qualityStatus': 'normal',
        'harvestDate': Timestamp.fromDate(item.$7),
        'notes': item.$8,
      }),
  ];
}

List<_SampleDocument> _sampleCircularFlows(DateTime now) {
  return [
    for (final flow in defaultCircularFlows(now))
      _sampleDoc(FirestoreCollections.circularFlows, flow.id, {
        'sourceModuleType': flow.sourceModuleType,
        'destinationModuleType': flow.destinationModuleType,
        'materialName': flow.materialName,
        'quantity': flow.quantity,
        'unit': flow.unit,
        'flowDate': Timestamp.fromDate(flow.flowDate),
        'notes': flow.notes,
      }),
  ];
}

List<_SampleDocument> _sampleSchedules(DateTime today) {
  final items = [
    (
      'sample_schedule_pakan_lele_sore',
      'Pemberian pakan lele sore',
      'lele',
      'feeding',
      today.add(const Duration(hours: 16)),
      'pending',
      'Berikan pakan secara merata dan catat respon makan.',
    ),
    (
      'sample_schedule_pakan_ayam_pagi',
      'Pemberian pakan ayam pagi',
      'ayam_kampung',
      'feeding',
      today.add(const Duration(hours: 7)),
      'pending',
      'Cek air minum sebelum pakan diberikan.',
    ),
    (
      'sample_schedule_panen_lele',
      'Persiapan panen lele',
      'lele',
      'harvest',
      today.add(const Duration(days: 4, hours: 8)),
      'pending',
      'Siapkan wadah, timbangan, dan area sortir.',
    ),
    (
      'sample_schedule_panen_sayur',
      'Panen sayur daun',
      'tanaman',
      'harvest',
      today.add(const Duration(days: 2, hours: 6)),
      'pending',
      'Panen pagi agar sayur tetap segar.',
    ),
    (
      'sample_schedule_pemupukan_tanaman',
      'Pemupukan tanaman',
      'tanaman',
      'fertilizing',
      today.add(const Duration(days: 1, hours: 8)),
      'pending',
      'Gunakan kompos matang dari kascing.',
    ),
    (
      'sample_schedule_cek_kandang',
      'Pengecekan kandang ayam',
      'ayam_kampung',
      'inspection',
      today.add(const Duration(hours: 10)),
      'pending',
      'Periksa kebersihan, pakan, air, dan ventilasi.',
    ),
    (
      'sample_schedule_cek_kolam',
      'Pengecekan kolam lele',
      'lele',
      'inspection',
      today.add(const Duration(hours: 9)),
      'pending',
      'Cek warna air, aerasi, dan respon ikan.',
    ),
    (
      'sample_schedule_input_sampah_maggot',
      'Input sampah organik maggot',
      'maggot_bsf',
      'feeding',
      today.subtract(const Duration(days: 1)).add(const Duration(hours: 8)),
      'pending',
      'Jadwal contoh overdue untuk menguji reminder.',
    ),
    (
      'sample_schedule_panen_kascing',
      'Panen kascing',
      'cacing_tanah',
      'harvest',
      today.add(const Duration(days: 5, hours: 8)),
      'pending',
      'Ayak kascing dan simpan di tempat teduh.',
    ),
    (
      'sample_schedule_sanitasi_alat',
      'Sanitasi alat kebun',
      'tanaman',
      'maintenance',
      today.add(const Duration(days: 3, hours: 15)),
      'pending',
      'Bersihkan alat setelah digunakan lintas area.',
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.schedules, item.$1, {
        'title': item.$2,
        'moduleType': item.$3,
        'type': item.$4,
        'date': Timestamp.fromDate(item.$5),
        'status': item.$6,
        'notes': item.$7,
        'updatedBy': SampleDataService.sampleCreatedBy,
        'isDeleted': false,
      }),
  ];
}

List<_SampleDocument> _sampleNotifications(DateTime today, String userId) {
  final items = [
    (
      'sample_notification_low_stock',
      'Stok Dedak Padi rendah',
      'Dedak Padi perlu dipantau dan disiapkan restock.',
      'low_stock',
      AppRoles.admin,
      userId,
      FirestoreCollections.inventory,
      'sample_inventory_dedak_padi',
    ),
    (
      'sample_notification_today_schedule',
      'Jadwal hari ini',
      'Ada jadwal pemberian pakan dan pengecekan kandang hari ini.',
      'production_reminder',
      AppRoles.admin,
      userId,
      FirestoreCollections.schedules,
      'sample_schedule_pakan_ayam_pagi',
    ),
    (
      'sample_notification_overdue_schedule',
      'Jadwal overdue',
      'Input sampah organik maggot sudah melewati waktu rencana.',
      'schedule_overdue',
      AppRoles.admin,
      userId,
      FirestoreCollections.schedules,
      'sample_schedule_input_sampah_maggot',
    ),
    (
      'sample_notification_production_reminder',
      'Pengingat produksi',
      'Catat hasil sampling bobot lele setelah pemberian pakan sore.',
      'production_reminder',
      AppRoles.admin,
      userId,
      FirestoreCollections.logbooks,
      'sample_logbook_lele_002',
    ),
    (
      'sample_notification_system_alert',
      'Alert sistem',
      'Data sampel demo v1 sudah siap digunakan untuk pengujian.',
      'system',
      'all',
      '',
      '',
      '',
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.notifications, item.$1, {
        'title': item.$2,
        'body': item.$3,
        'type': item.$4,
        'targetRole': item.$5,
        'userId': item.$6,
        'relatedCollection': item.$7,
        'relatedId': item.$8,
        'isRead': false,
        'scheduledAt': Timestamp.fromDate(today.add(const Duration(hours: 16))),
        'updatedBy': SampleDataService.sampleCreatedBy,
        'isDeleted': false,
      }),
  ];
}

List<_SampleDocument> _sampleEducation() {
  return [
    _educationArticle(
      'sample_education_article_ayam',
      'Dasar Perawatan Ayam Kampung',
      'ayam_kampung',
      'Panduan singkat perawatan ayam kampung di Kebun Sei.',
      'Ayam kampung perlu dipantau pakan, air minum, kebersihan kandang, dan kesehatannya secara rutin.',
      ['ayam', 'pakan', 'kandang'],
    ),
    _educationArticle(
      'sample_education_article_lele',
      'Manajemen Pakan Lele Harian',
      'lele',
      'Cara menjaga pemberian pakan lele tetap efisien.',
      'Pakan lele diberikan bertahap sambil melihat respon makan, kondisi air, dan umur produksi.',
      ['lele', 'pakan', 'kolam'],
    ),
    _educationArticle(
      'sample_education_article_kompos',
      'Pemanfaatan Kompos untuk Tanaman',
      'tanaman',
      'Ringkasan pemupukan tanaman menggunakan kompos Kebun Sei.',
      'Kompos matang diberikan di sekitar pangkal tanaman dan dikombinasikan dengan penyiraman cukup.',
      ['tanaman', 'kompos', 'pupuk'],
    ),
    _educationVideo(
      'sample_education_video_maggot',
      'Tutorial Perawatan Maggot BSF',
      'maggot_bsf',
      'https://www.youtube.com/watch?v=dummy',
      '08:15',
    ),
    _educationVideo(
      'sample_education_video_cacing',
      'Tutorial Media Cacing Tanah',
      'cacing_tanah',
      'https://www.youtube.com/watch?v=dummy',
      '06:30',
    ),
    _educationVideo(
      'sample_education_video_lele',
      'Tutorial Pengecekan Kolam Lele',
      'lele',
      'https://www.youtube.com/watch?v=dummy',
      '07:45',
    ),
    _educationSop(
      'sample_education_sop_lele',
      'SOP Pemberian Pakan Lele',
      'lele',
      [
        'Cek kondisi kolam',
        'Siapkan pakan sesuai takaran',
        'Berikan pakan secara merata',
        'Catat respon makan lele di logbook',
      ],
    ),
    _educationSop(
      'sample_education_sop_ayam',
      'SOP Pembersihan Kandang Ayam',
      'ayam_kampung',
      [
        'Pindahkan sisa pakan dan wadah minum',
        'Bersihkan lantai dan alas kandang',
        'Pastikan ventilasi kandang tidak tertutup',
        'Catat kondisi kandang setelah dibersihkan',
      ],
    ),
    _educationSop(
      'sample_education_sop_tanaman',
      'SOP Pemupukan Tanaman',
      'tanaman',
      [
        'Cek kelembapan media tanam',
        'Siapkan kompos matang sesuai kebutuhan',
        'Taburkan kompos di sekitar pangkal tanaman',
        'Siram secukupnya setelah pemupukan',
      ],
    ),
  ];
}

_SampleDocument _educationArticle(
  String id,
  String title,
  String moduleType,
  String summary,
  String content,
  List<String> tags,
) {
  return _sampleDoc(FirestoreCollections.educationContents, id, {
    'title': title,
    'type': 'artikel',
    'status': 'published',
    'moduleType': moduleType,
    'category': 'Panduan',
    'tags': tags,
    'authorId': SampleDataService.sampleCreatedBy,
    'updatedBy': SampleDataService.sampleCreatedBy,
    'isDeleted': false,
    'summary': summary,
    'content': content,
    'thumbnailUrl': '',
    'externalVideoUrl': '',
    'duration': '',
    'steps': <String>[],
    'toolsNeeded': <String>[],
    'safetyNotes': '',
  });
}

_SampleDocument _educationVideo(
  String id,
  String title,
  String moduleType,
  String externalVideoUrl,
  String duration,
) {
  return _sampleDoc(FirestoreCollections.educationContents, id, {
    'title': title,
    'type': 'video',
    'status': 'published',
    'moduleType': moduleType,
    'category': 'Video Tutorial',
    'tags': ['video', moduleType],
    'authorId': SampleDataService.sampleCreatedBy,
    'updatedBy': SampleDataService.sampleCreatedBy,
    'isDeleted': false,
    'summary': 'Video tutorial operasional untuk modul $moduleType.',
    'content': '',
    'thumbnailUrl': '',
    'externalVideoUrl': externalVideoUrl,
    'duration': duration,
    'steps': <String>[],
    'toolsNeeded': <String>[],
    'safetyNotes': '',
  });
}

_SampleDocument _educationSop(
  String id,
  String title,
  String moduleType,
  List<String> steps,
) {
  return _sampleDoc(FirestoreCollections.educationContents, id, {
    'title': title,
    'type': 'sop',
    'status': 'published',
    'moduleType': moduleType,
    'category': 'SOP Operasional',
    'tags': ['sop', moduleType],
    'authorId': SampleDataService.sampleCreatedBy,
    'updatedBy': SampleDataService.sampleCreatedBy,
    'isDeleted': false,
    'summary': 'Langkah operasional standar untuk modul $moduleType.',
    'content': '',
    'thumbnailUrl': '',
    'externalVideoUrl': '',
    'duration': '',
    'steps': steps,
    'toolsNeeded': ['Logbook SeiCycle', 'Alat operasional sesuai modul'],
    'safetyNotes': 'Gunakan alat kerja dengan aman dan catat hasil pekerjaan.',
  });
}

List<_SampleDocument> _sampleFinance(DateTime today) {
  final items = [
    (
      'sample_finance_income_panen_001',
      'income',
      'Panen',
      350000.0,
      today.subtract(const Duration(days: 2)),
      'Pemasukan dari penjualan hasil panen sayur.',
      'tunai',
      'tanaman',
    ),
    (
      'sample_finance_income_panen_002',
      'income',
      'Panen',
      420000.0,
      today.subtract(const Duration(days: 5)),
      'Pemasukan dari penjualan lele konsumsi.',
      'transfer',
      'lele',
    ),
    (
      'sample_finance_income_kascing_001',
      'income',
      'Kascing',
      180000.0,
      today.subtract(const Duration(days: 9)),
      'Penjualan kascing untuk kebun sekitar.',
      'tunai',
      'cacing_tanah',
    ),
    (
      'sample_finance_income_maggot_001',
      'income',
      'Maggot',
      160000.0,
      today.subtract(const Duration(days: 11)),
      'Pemasukan dari penjualan maggot segar.',
      'tunai',
      'maggot_bsf',
    ),
    (
      'sample_finance_income_telur_001',
      'income',
      'Telur',
      210000.0,
      today.subtract(const Duration(days: 12)),
      'Pemasukan dari penjualan telur ayam kampung.',
      'tunai',
      'ayam_kampung',
    ),
    (
      'sample_finance_expense_pakan_ayam_001',
      'expense',
      'Pakan',
      120000.0,
      today.subtract(const Duration(days: 1)),
      'Pembelian pakan ayam kampung.',
      'tunai',
      'ayam_kampung',
    ),
    (
      'sample_finance_expense_pakan_lele_001',
      'expense',
      'Pakan',
      160000.0,
      today.subtract(const Duration(days: 3)),
      'Pembelian pakan lele harian.',
      'transfer',
      'lele',
    ),
    (
      'sample_finance_expense_bibit_001',
      'expense',
      'Bibit',
      95000.0,
      today.subtract(const Duration(days: 4)),
      'Pembelian bibit sayur daun.',
      'tunai',
      'tanaman',
    ),
    (
      'sample_finance_expense_operasional_001',
      'expense',
      'Operasional',
      75000.0,
      today.subtract(const Duration(days: 6)),
      'Biaya perlengkapan sanitasi alat.',
      'tunai',
      'tanaman',
    ),
    (
      'sample_finance_expense_media_maggot_001',
      'expense',
      'Media',
      65000.0,
      today.subtract(const Duration(days: 7)),
      'Pembelian bahan tambahan media maggot.',
      'tunai',
      'maggot_bsf',
    ),
    (
      'sample_finance_expense_suplemen_001',
      'expense',
      'Suplemen',
      85000.0,
      today.subtract(const Duration(days: 8)),
      'Pembelian vitamin ayam dan probiotik lele.',
      'transfer',
      'ayam_kampung',
    ),
    (
      'sample_finance_expense_alat_001',
      'expense',
      'Alat Kebun',
      135000.0,
      today.subtract(const Duration(days: 10)),
      'Pembelian wadah panen dan sarung tangan.',
      'tunai',
      'tanaman',
    ),
    (
      'sample_finance_expense_operasional_002',
      'expense',
      'Operasional',
      50000.0,
      today.subtract(const Duration(days: 14)),
      'Transportasi distribusi hasil panen lokal.',
      'tunai',
      'tanaman',
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.financeTransactions, item.$1, {
        'type': item.$2,
        'category': item.$3,
        'amount': item.$4,
        'date': Timestamp.fromDate(item.$5),
        'description': item.$6,
        'notes': item.$6,
        'paymentMethod': item.$7,
        'moduleType': item.$8,
        'updatedBy': SampleDataService.sampleCreatedBy,
        'isDeleted': false,
      }),
  ];
}

List<_SampleDocument> _sampleRecommendations(DateTime today) {
  final items = [
    (
      'sample_recommendation_restock_lele',
      'Stok pakan lele mulai rendah',
      'Segera lakukan restock karena stok berada di bawah batas minimum.',
      'inventory',
      'high',
      'lele',
      FirestoreCollections.inventory,
      'sample_inventory_pakan_lele',
      today.add(const Duration(days: 7)),
    ),
    (
      'sample_recommendation_update_logbook',
      'Update logbook maggot BSF',
      'Tambahkan catatan terbaru agar kondisi media dan produksi tetap terpantau.',
      'logbook',
      'normal',
      'maggot_bsf',
      FirestoreCollections.logbooks,
      'sample_logbook_maggot_001',
      today.add(const Duration(days: 3)),
    ),
    (
      'sample_recommendation_prepare_harvest',
      'Persiapan panen lele',
      'Siapkan wadah, timbangan, dan jadwal sortir karena panen semakin dekat.',
      'harvest_prediction',
      'high',
      'lele',
      FirestoreCollections.schedules,
      'sample_schedule_panen_lele',
      today.add(const Duration(days: 5)),
    ),
    (
      'sample_recommendation_finance_eval',
      'Evaluasi biaya operasional',
      'Tinjau pengeluaran pakan dan suplemen agar margin panen tetap sehat.',
      'finance',
      'normal',
      '',
      FirestoreCollections.financeTransactions,
      'sample_finance_expense_pakan_lele_001',
      today.add(const Duration(days: 10)),
    ),
    (
      'sample_recommendation_overdue_schedule',
      'Tindak lanjuti jadwal overdue',
      'Pengecekan media maggot sudah lewat jadwal dan perlu segera ditandai selesai.',
      'schedule',
      'high',
      'maggot_bsf',
      FirestoreCollections.schedules,
      'sample_schedule_input_sampah_maggot',
      today.add(const Duration(days: 2)),
    ),
  ];

  return [
    for (final item in items)
      _sampleDoc(FirestoreCollections.recommendations, item.$1, {
        'title': item.$2,
        'description': item.$3,
        'type': item.$4,
        'priority': item.$5,
        if (item.$6.isNotEmpty) 'moduleType': item.$6,
        'sourceCollection': item.$7,
        'sourceId': item.$8,
        'validUntil': Timestamp.fromDate(item.$9),
        'isResolved': false,
      }),
  ];
}

_SampleDocument _sampleDoc(
  String collection,
  String id,
  Map<String, dynamic> data,
) {
  return _SampleDocument(
    collection: collection,
    id: id,
    data: {
      'id': id,
      ...data,
      'isSampleData': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': SampleDataService.sampleCreatedBy,
      'sampleVersion': SampleDataService.sampleVersion,
    },
  );
}

const _sampleCollections = [
  FirestoreCollections.users,
  FirestoreCollections.farmModules,
  FirestoreCollections.logbooks,
  FirestoreCollections.inventory,
  FirestoreCollections.inventoryTransactions,
  FirestoreCollections.productionResults,
  FirestoreCollections.circularFlows,
  FirestoreCollections.schedules,
  FirestoreCollections.notifications,
  FirestoreCollections.educationContents,
  FirestoreCollections.financeTransactions,
  FirestoreCollections.recommendations,
];

const _representativeDocuments = [
  _SampleDocumentRef(FirestoreCollections.users, 'sample_user_admin'),
  _SampleDocumentRef(FirestoreCollections.farmModules, 'ayam_kampung'),
  _SampleDocumentRef(FirestoreCollections.logbooks, 'sample_logbook_ayam_001'),
  _SampleDocumentRef(
    FirestoreCollections.inventory,
    'sample_inventory_pakan_lele',
  ),
  _SampleDocumentRef(
    FirestoreCollections.inventoryTransactions,
    'sample_inventory_txn_ayam_dedak',
  ),
  _SampleDocumentRef(
    FirestoreCollections.productionResults,
    'sample_production_telur_ayam',
  ),
  _SampleDocumentRef(
    FirestoreCollections.circularFlows,
    'tanaman_to_maggot_bsf',
  ),
  _SampleDocumentRef(
    FirestoreCollections.schedules,
    'sample_schedule_pakan_lele_sore',
  ),
  _SampleDocumentRef(
    FirestoreCollections.notifications,
    'sample_notification_low_stock',
  ),
  _SampleDocumentRef(
    FirestoreCollections.educationContents,
    'sample_education_sop_lele',
  ),
  _SampleDocumentRef(
    FirestoreCollections.financeTransactions,
    'sample_finance_income_panen_001',
  ),
  _SampleDocumentRef(
    FirestoreCollections.recommendations,
    'sample_recommendation_restock_lele',
  ),
];

class _SampleDocument {
  const _SampleDocument({
    required this.collection,
    required this.id,
    required this.data,
  });

  final String collection;
  final String id;
  final Map<String, dynamic> data;
}

class _SampleDocumentRef {
  const _SampleDocumentRef(this.collection, this.id);

  final String collection;
  final String id;
}

class _SampleSeedContext {
  const _SampleSeedContext({required this.userId});

  final String userId;
}
