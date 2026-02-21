import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});

  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    _TabInfo('Ayam', Icons.egg_alt_outlined),
    _TabInfo('Maggot', Icons.bug_report_outlined),
    _TabInfo('Cacing', Icons.grass_outlined),
    _TabInfo('Tanaman', Icons.eco_outlined),
    _TabInfo('Lele', Icons.water_drop_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LogbookHeader(tabController: _tabController, tabs: _tabs),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AyamModule(),
              MaggotModule(),
              CacingModule(),
              TanamanModule(),
              LeleModule(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;

  const _TabInfo(this.label, this.icon);
}

// ─── Logbook Header ───────────────────────────────────────────────────────────

class _LogbookHeader extends StatelessWidget {
  final TabController tabController;
  final List<_TabInfo> tabs;

  const _LogbookHeader({required this.tabController, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logbook Operasional',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Catat aktivitas harian setiap modul budidaya',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: tabs
                .map(
                  (t) => Tab(
                    height: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 16),
                        const SizedBox(width: 6),
                        Text('Modul ${t.label}'),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ─── Form Helpers ─────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget _buildField(
  String label,
  String hint, {
  TextInputType type = TextInputType.text,
  String? suffix,
  int maxLines = 1,
  String? initialValue,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: initialValue,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffix: suffix != null
            ? Text(
                suffix,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
      ),
    ),
  );
}

Widget _buildResponsiveFormRow(List<Widget> fields, double maxWidth) {
  if (maxWidth >= 600) {
    // Multi-column on wide screens
    return Wrap(
      spacing: 16,
      runSpacing: 0,
      children: fields
          .map((f) => SizedBox(width: (maxWidth - 56) / 2, child: f))
          .toList(),
    );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: fields,
  );
}

Widget _buildSubmitRow() {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.history_outlined, size: 18),
          label: const Text('Lihat Riwayat'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.save_outlined, size: 18),
          label: const Text('Simpan Catatan'),
        ),
      ),
    ],
  );
}

// ─── MODULE: AYAM ─────────────────────────────────────────────────────────────

class AyamModule extends StatefulWidget {
  const AyamModule({super.key});

  @override
  State<AyamModule> createState() => _AyamModuleState();
}

class _AyamModuleState extends State<AyamModule> {
  double _mortalitas = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ModuleBanner(
            label: 'Modul Ayam',
            desc: '150 ekor ayam kampung & petelur · Target 85+ telur/hari',
            icon: Icons.egg_alt_outlined,
            color: AppColors.warning,
            stats: const [
              _BannerStat('Populasi', '150 ekor'),
              _BannerStat('Produksi Kemarin', '88 butir'),
              _BannerStat('Target Harian', '85 butir'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              return Column(
                children: [
                  _FormCard(
                    title: 'Input Harian',
                    icon: Icons.edit_outlined,
                    color: AppColors.warning,
                    children: [
                      _buildResponsiveFormRow([
                        _buildField(
                          'Populasi Aktif',
                          'Jumlah ekor',
                          type: TextInputType.number,
                          suffix: 'ekor',
                          initialValue: '150',
                        ),
                        _buildField(
                          'Konsumsi Pakan',
                          'Gram per ekor per hari',
                          type: TextInputType.number,
                          suffix: 'g/ekor',
                          initialValue: '50',
                        ),
                      ], c.maxWidth),
                      _buildResponsiveFormRow([
                        _buildField(
                          'Produksi Telur Hari Ini',
                          'Jumlah butir',
                          type: TextInputType.number,
                          suffix: 'butir',
                          initialValue: '85',
                        ),
                        _buildField(
                          'Berat Rata-rata Telur',
                          'Gram per butir',
                          type: TextInputType.number,
                          suffix: 'gram',
                          initialValue: '58',
                        ),
                      ], c.maxWidth),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Mortalitas Hari Ini: ',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${_mortalitas.toInt()} ekor',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _mortalitas,
                              min: 0,
                              max: 10,
                              divisions: 10,
                              activeColor: AppColors.error,
                              inactiveColor: AppColors.error.withValues(alpha: 0.2),
                              onChanged: (v) => setState(() => _mortalitas = v),
                            ),
                          ],
                        ),
                      ),
                      _buildField(
                        'Catatan Kejadian Khusus',
                        'Contoh: ayam terlihat lesu, perlu vaksin...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  _FormCard(
                    title: 'Rincian Pakan & Nutrisi',
                    icon: Icons.restaurant_outlined,
                    color: AppColors.accentBrown,
                    children: [
                      _buildResponsiveFormRow([
                        _buildField(
                          'Dedak Padi',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '5',
                        ),
                        _buildField(
                          'Talas & Pepaya',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '2',
                        ),
                      ], c.maxWidth),
                      _buildResponsiveFormRow([
                        _buildField(
                          'Maggot Segar (suplemen)',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '0.5',
                        ),
                        _buildField(
                          'Total Biaya Pakan',
                          'Rp',
                          type: TextInputType.number,
                          suffix: 'Rp',
                          initialValue: '15000',
                        ),
                      ], c.maxWidth),
                    ],
                  ),
                  _FormCard(
                    title: 'Catatan Kesehatan',
                    icon: Icons.health_and_safety_outlined,
                    color: AppColors.info,
                    children: [
                      _buildResponsiveFormRow([
                        _buildField(
                          'Kondisi Kandang',
                          '1-10',
                          type: TextInputType.number,
                          initialValue: '9',
                        ),
                        _buildField(
                          'Suhu Kandang',
                          '°C',
                          type: TextInputType.number,
                          suffix: '°C',
                          initialValue: '27',
                        ),
                      ], c.maxWidth),
                      _buildField(
                        'Gejala / Penyakit Terdeteksi',
                        'Kosongkan jika tidak ada kejadian',
                        maxLines: 2,
                      ),
                    ],
                  ),
                  _buildSubmitRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── MODULE: MAGGOT ───────────────────────────────────────────────────────────

class MaggotModule extends StatefulWidget {
  const MaggotModule({super.key});

  @override
  State<MaggotModule> createState() => _MaggotModuleState();
}

class _MaggotModuleState extends State<MaggotModule> {
  double _faseHari = 12;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ModuleBanner(
            label: 'Modul Maggot BSF',
            desc: 'Black Soldier Fly · Batch aktif 5 rak · Siklus 14 hari',
            icon: Icons.bug_report_outlined,
            color: AppColors.accentLightGreen,
            stats: const [
              _BannerStat('Limbah Masuk', '50 kg/minggu'),
              _BannerStat('Batch Aktif', 'Hari ke-12'),
              _BannerStat('Est. Panen', '18–20 kg'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              return Column(
                children: [
                  _FormCard(
                    title: 'Input Limbah Organik',
                    icon: Icons.recycling_outlined,
                    color: AppColors.accentBrown,
                    children: [
                      _buildResponsiveFormRow([
                        _buildField(
                          'Volume Limbah Masuk',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '12',
                        ),
                        _buildField(
                          'Jenis Limbah Utama',
                          'sisa nasi, sayur, dll.',
                          initialValue: 'Sisa makanan dapur',
                        ),
                      ], c.maxWidth),
                      _buildResponsiveFormRow([
                        _buildField(
                          'Kadar Air Limbah',
                          '% estimasi',
                          type: TextInputType.number,
                          suffix: '%',
                          initialValue: '75',
                        ),
                        _buildField(
                          'Asal Limbah',
                          'RT / warung / pasar',
                          initialValue: 'Rumah tangga sekitar',
                        ),
                      ], c.maxWidth),
                    ],
                  ),
                  _FormCard(
                    title: 'Status Larva & Fase Pertumbuhan',
                    icon: Icons.timeline_outlined,
                    color: AppColors.accentLightGreen,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Fase Larva – Hari ke-: ',
                                  style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${_faseHari.toInt()}',
                                  style: const TextStyle(
                                    color: AppColors.accentLightGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Text(
                                  '/14',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _faseHari,
                              min: 1,
                              max: 14,
                              divisions: 13,
                              activeColor: AppColors.accentLightGreen,
                              inactiveColor: AppColors.accentLightGreen
                                  .withValues(alpha: 0.2),
                              onChanged: (v) => setState(() => _faseHari = v),
                            ),
                            _PhaseBadge(hari: _faseHari.toInt()),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      _buildResponsiveFormRow([
                        _buildField(
                          'Suhu Media',
                          '°C',
                          type: TextInputType.number,
                          suffix: '°C',
                          initialValue: '30',
                        ),
                        _buildField(
                          'Jumlah Rak Aktif',
                          'unit',
                          type: TextInputType.number,
                          suffix: 'rak',
                          initialValue: '5',
                        ),
                      ], c.maxWidth),
                    ],
                  ),
                  _FormCard(
                    title: 'Estimasi & Rencana Panen',
                    icon: Icons.agriculture_outlined,
                    color: AppColors.primaryGreen,
                    children: [
                      _buildResponsiveFormRow([
                        _buildField(
                          'Estimasi Panen Larva',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '18',
                        ),
                        _buildField(
                          'Target Panen Larva',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '20',
                        ),
                      ], c.maxWidth),
                      _buildResponsiveFormRow([
                        _buildField(
                          'Panen Prepupa (kering)',
                          'kg',
                          type: TextInputType.number,
                          suffix: 'kg',
                          initialValue: '0',
                        ),
                        _buildField(
                          'Alokasi Larva (lele/ayam)',
                          '%',
                          type: TextInputType.number,
                          suffix: '% lele',
                          initialValue: '80',
                        ),
                      ], c.maxWidth),
                      _buildField(
                        'Catatan Batch Ini',
                        'kualitas, anomali, suhu, dll.',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  _buildSubmitRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhaseBadge extends StatelessWidget {
  final int hari;

  const _PhaseBadge({required this.hari});

  @override
  Widget build(BuildContext context) {
    String phase;
    Color color;
    if (hari <= 3) {
      phase = 'Fase Telur → Instar 1 (1–3 hari)';
      color = AppColors.info;
    } else if (hari <= 7) {
      phase = 'Fase Instar Awal (4–7 hari) – pertumbuhan aktif';
      color = AppColors.accentLightGreen;
    } else if (hari <= 12) {
      phase = 'Fase Instar Akhir (8–12 hari) – feeding masif';
      color = AppColors.warning;
    } else {
      phase = '🌾 Prepupa (13–14 hari) – SIAP PANEN';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              phase,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MODULE STUBS ─────────────────────────────────────────────────────────────

class CacingModule extends StatelessWidget {
  const CacingModule({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ModuleBanner(
            label: 'Modul Cacing Tanah (ANC)',
            desc: '10 kg bibit cacing · Kelembaban 70% · Pakan 3x/minggu',
            icon: Icons.grass_outlined,
            color: AppColors.primaryGreenDark,
            stats: const [
              _BannerStat('Bibit', '10 kg'),
              _BannerStat('Kelembaban', '70%'),
              _BannerStat('Est. Kascing', '320 kg/bln'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              return _FormCard(
                title: 'Input Harian – Cacing',
                icon: Icons.edit_outlined,
                color: AppColors.primaryGreenDark,
                children: [
                  _buildResponsiveFormRow([
                    _buildField(
                      'Jumlah Bibit',
                      'kg',
                      type: TextInputType.number,
                      suffix: 'kg',
                      initialValue: '10',
                    ),
                    _buildField(
                      'Kelembaban Media',
                      '%',
                      type: TextInputType.number,
                      suffix: '%',
                      initialValue: '70',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Pakan Diberikan',
                      'kg',
                      type: TextInputType.number,
                      suffix: 'kg',
                      initialValue: '2',
                    ),
                    _buildField(
                      'Jenis Pakan',
                      'Limbah organik, kotoran...',
                      initialValue: 'Limbah dapur + kotoran ayam',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Hasil Kascing (jika panen)',
                      'kg',
                      type: TextInputType.number,
                      suffix: 'kg',
                    ),
                    _buildField(
                      'Estimasi Panen Berikutnya',
                      'hari ke-',
                      type: TextInputType.number,
                      suffix: 'hari lagi',
                    ),
                  ], c.maxWidth),
                  _buildField(
                    'Catatan Kejadian',
                    'kondisi media, suhu, dll.',
                    maxLines: 2,
                  ),
                  _buildSubmitRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class TanamanModule extends StatelessWidget {
  const TanamanModule({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ModuleBanner(
            label: 'Modul Tanaman Pangan Organik',
            desc: 'Talas · Singkong · Kacang Panjang · Pepaya · 500 m² lahan',
            icon: Icons.eco_outlined,
            color: AppColors.success,
            stats: const [
              _BannerStat('Komoditas', '4 jenis'),
              _BannerStat('Luas Lahan', '±200 m²'),
              _BannerStat('Pupuk', 'Kascing mandiri'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              return _FormCard(
                title: 'Data Tanam & Pertumbuhan',
                icon: Icons.edit_outlined,
                color: AppColors.success,
                children: [
                  _buildResponsiveFormRow([
                    _buildField(
                      'Jenis Tanaman',
                      'Talas, singkong, dll.',
                      initialValue: 'Talas Paya',
                    ),
                    _buildField(
                      'Blok / Lokasi',
                      'Blok A, B, C...',
                      initialValue: 'Blok A',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Tanggal Tanam',
                      'DD/MM/YYYY',
                      initialValue: '01/01/2026',
                    ),
                    _buildField(
                      'Usia Tanaman',
                      'hari',
                      type: TextInputType.number,
                      suffix: 'hari',
                      initialValue: '52',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Tinggi Tanaman',
                      'cm',
                      type: TextInputType.number,
                      suffix: 'cm',
                      initialValue: '85',
                    ),
                    _buildField(
                      'Jumlah Daun',
                      'lembar',
                      type: TextInputType.number,
                      suffix: 'lbr',
                      initialValue: '12',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Pupuk Kascing Cair',
                      'L',
                      type: TextInputType.number,
                      suffix: 'L/m²',
                      initialValue: '2',
                    ),
                    _buildField(
                      'Jadwal Pemupukan Berikutnya',
                      'DD/MM/YYYY',
                      initialValue: '28/02/2026',
                    ),
                  ], c.maxWidth),
                  _buildField(
                    'Catatan Kondisi Tanaman',
                    'hama, pertumbuhan, dll.',
                    maxLines: 2,
                  ),
                  _buildSubmitRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class LeleModule extends StatelessWidget {
  const LeleModule({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _ModuleBanner(
            label: 'Modul Lele Organik',
            desc: '800 ekor tebar · Pakan maggot · Kolam bioflok · SR 89%',
            icon: Icons.water_drop_outlined,
            color: AppColors.info,
            stats: const [
              _BannerStat('Tebar Benih', '800 ekor'),
              _BannerStat('Survival Rate', '89%'),
              _BannerStat('Pakan/Hari', '5 kg maggot'),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              return _FormCard(
                title: 'Input Harian – Lele',
                icon: Icons.edit_outlined,
                color: AppColors.info,
                children: [
                  _buildResponsiveFormRow([
                    _buildField(
                      'Jumlah Tebar Benih',
                      'ekor',
                      type: TextInputType.number,
                      suffix: 'ekor',
                      initialValue: '800',
                    ),
                    _buildField(
                      'Survival Rate Saat Ini',
                      '%',
                      type: TextInputType.number,
                      suffix: '%',
                      initialValue: '89',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Pakan Maggot Pagi',
                      'kg',
                      type: TextInputType.number,
                      suffix: 'kg',
                      initialValue: '2.5',
                    ),
                    _buildField(
                      'Pakan Maggot Sore',
                      'kg',
                      type: TextInputType.number,
                      suffix: 'kg',
                      initialValue: '2.5',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'pH Air Kolam',
                      '6.5–8.0 ideal',
                      type: TextInputType.numberWithOptions(decimal: true),
                      suffix: 'pH',
                      initialValue: '7.2',
                    ),
                    _buildField(
                      'Suhu Air',
                      '°C',
                      type: TextInputType.number,
                      suffix: '°C',
                      initialValue: '28',
                    ),
                  ], c.maxWidth),
                  _buildResponsiveFormRow([
                    _buildField(
                      'Bobot Rata-rata',
                      'gram/ekor',
                      type: TextInputType.number,
                      suffix: 'g',
                      initialValue: '150',
                    ),
                    _buildField(
                      'Estimasi Panen',
                      'hari lagi',
                      type: TextInputType.number,
                      suffix: 'hari',
                      initialValue: '30',
                    ),
                  ], c.maxWidth),
                  _buildField(
                    'Catatan Kolam',
                    'kualitas air, kematian, dll.',
                    maxLines: 2,
                  ),
                  _buildSubmitRow(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Module Banner ────────────────────────────────────────────────────────────

class _BannerStat {
  final String label;
  final String value;

  const _BannerStat(this.label, this.value);
}

class _ModuleBanner extends StatelessWidget {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final List<_BannerStat> stats;

  const _ModuleBanner({
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: stats
                .map(
                  (s) => Expanded(
                    child: Column(
                      children: [
                        Text(
                          s.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          s.label,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
