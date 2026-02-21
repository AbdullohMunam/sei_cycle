import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Stat Card Data ─────────────────────────────────────────────────────────

class StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double progress; // 0.0 – 1.0

  const StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
  });
}

class AppData {
  static const List<StatCardData> dashboardStats = [
    StatCardData(
      title: 'Total Populasi Ternak',
      value: '1.050 ekor',
      subtitle: 'Ayam 150 + Lele 800 + Cacing 100 unit rak',
      icon: Icons.pets_outlined,
      color: AppColors.primaryGreen,
      progress: 0.84,
    ),
    StatCardData(
      title: 'Volume Limbah Terolah',
      value: '50 kg/minggu',
      subtitle: 'Sisa makanan → media maggot & cacing',
      icon: Icons.recycling_outlined,
      color: AppColors.accentBrown,
      progress: 0.71,
    ),
    StatCardData(
      title: 'Total Produksi',
      value: '85 telur/hari',
      subtitle: '18 kg maggot · 320 kg kascing/bln',
      icon: Icons.agriculture_outlined,
      color: AppColors.success,
      progress: 0.89,
    ),
    StatCardData(
      title: 'Estimasi Nilai Ekonomi',
      value: 'Rp 20 jt/bln',
      subtitle: 'Target proyeksi Rp 96 jt/periode',
      icon: Icons.monetization_on_outlined,
      color: AppColors.warning,
      progress: 0.62,
    ),
  ];

  // ─── Nutrient Flow Steps ─────────────────────────────────────────────────

  static const List<Map<String, dynamic>> nutrientFlow = [
    {
      'label': 'Limbah\nDapur',
      'icon': Icons.delete_outline,
      'color': Color(0xFF8B6F47),
    },
    {
      'label': 'Maggot\nBSF',
      'icon': Icons.bug_report_outlined,
      'color': Color(0xFF6DBF67),
    },
    {
      'label': 'Pakan\nLele',
      'icon': Icons.set_meal_outlined,
      'color': Color(0xFF3B82F6),
    },
    {
      'label': 'Air\nKolam',
      'icon': Icons.water_drop_outlined,
      'color': Color(0xFF06B6D4),
    },
    {
      'label': 'Cacing &\nKascing',
      'icon': Icons.grass_outlined,
      'color': Color(0xFF2D6A27),
    },
    {
      'label': 'Tanaman\nPangan',
      'icon': Icons.eco_outlined,
      'color': Color(0xFF10B981),
    },
    {
      'label': 'Pakan\nAyam',
      'icon': Icons.egg_alt_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'label': 'Limbah\nAyam',
      'icon': Icons.loop_outlined,
      'color': Color(0xFF8B6F47),
    },
  ];

  // ─── Notification Data ───────────────────────────────────────────────────

  static const List<NotifData> notifications = [
    NotifData(
      type: NotifType.info,
      title: 'Pakan Cacing – Jadwal Rutin',
      body:
          'Saatnya memberi pakan cacing ANC. Frekuensi: 3x/minggu. Gunakan limbah organik ±2 kg.',
      time: '06:00',
      module: 'Modul Cacing',
    ),
    NotifData(
      type: NotifType.info,
      title: 'Pakan Ayam – Pagi',
      body:
          'Berikan 150 ekor ayam kampung pakan pagi. Porsi: 50 g/ekor → total 7,5 kg dedak + talas.',
      time: '06:30',
      module: 'Modul Ayam',
    ),
    NotifData(
      type: NotifType.info,
      title: 'Pakan Lele – Pagi',
      body:
          'Kolam lele perlu 2,5 kg maggot segar. SR saat ini 89%. Cek kondisi air kolam bioflok.',
      time: '07:00',
      module: 'Modul Lele',
    ),
    NotifData(
      type: NotifType.warning,
      title: '⚠️ Overstock Limbah Organik',
      body:
          'Volume limbah dapur telah mencapai 48 kg. Kapasitas maggot bed hanya 50 kg. Segera proses ke media baru.',
      time: '09:15',
      module: 'Modul Maggot',
    ),
    NotifData(
      type: NotifType.success,
      title: '🌾 Estimasi Panen Maggot Optimal',
      body:
          'Batch BSF hari ke-12 siap panen dalam 2 hari. Estimasi hasil: 18–20 kg larva segar. Siapkan wadah panen.',
      time: '10:00',
      module: 'Modul Maggot',
    ),
    NotifData(
      type: NotifType.info,
      title: 'Pakan Ayam – Sore',
      body:
          'Pemberian pakan sore untuk 150 ekor. Rekam produksi telur harian di logbook Modul Ayam.',
      time: '16:00',
      module: 'Modul Ayam',
    ),
    NotifData(
      type: NotifType.info,
      title: 'Pakan Lele – Sore',
      body:
          'Porsi pakan lele sore 2,5 kg maggot. Catat survival rate dan pertumbuhan bobot rata-rata.',
      time: '16:30',
      module: 'Modul Lele',
    ),
    NotifData(
      type: NotifType.success,
      title: '🌱 Jadwal Pemupukan Tanaman',
      body:
          'Aplikasikan pupuk kascing cair 2 L/m² pada tanaman talas & singkong. Blok A dan B.',
      time: '17:00',
      module: 'Modul Tanaman',
    ),
    NotifData(
      type: NotifType.warning,
      title: '⚠️ Kelembaban Cacing Rendah',
      body:
          'Kelembaban media cacing turun ke 58%. Ideal: 70–80%. Siram dengan air kolam lele secukupnya.',
      time: '08:00',
      module: 'Modul Cacing',
    ),
    NotifData(
      type: NotifType.success,
      title: '🎉 Target Produksi Telur Tercapai',
      body:
          'Produksi telur hari ini 90 butir – melebihi target 85 butir. Estimasi pendapatan: Rp 270.000.',
      time: '18:00',
      module: 'Modul Ayam',
    ),
  ];
}

// ─── Notification Model ──────────────────────────────────────────────────────

enum NotifType { info, warning, success }

class NotifData {
  final NotifType type;
  final String title;
  final String body;
  final String time;
  final String module;

  const NotifData({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.module,
  });

  Color get color {
    switch (type) {
      case NotifType.info:
        return AppColors.info;
      case NotifType.warning:
        return AppColors.warning;
      case NotifType.success:
        return AppColors.success;
    }
  }

  IconData get icon {
    switch (type) {
      case NotifType.info:
        return Icons.notifications_outlined;
      case NotifType.warning:
        return Icons.warning_amber_outlined;
      case NotifType.success:
        return Icons.check_circle_outline;
    }
  }
}
