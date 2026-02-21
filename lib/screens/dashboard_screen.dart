import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';
import '../widgets/common_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Ringkasan Operasional',
            subtitle: 'Data real-time Kebun Sei hari ini',
            trailing: Chip(
              label: const Text('Live'),
              avatar: const Icon(
                Icons.circle,
                color: AppColors.success,
                size: 10,
              ),
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
              labelStyle: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          _StatsGrid(),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Sistem Aliran Nutrisi',
            subtitle:
                'Siklus tertutup Kebun Sei – zero waste integrated farming',
          ),
          const NutrientFlowCard(),
          const SizedBox(height: 28),
          SectionHeader(
            title: 'Aktivitas Hari Ini',
            subtitle: 'Sabtu, 22 Februari 2026',
          ),
          _ActivityTimeline(),
          const SizedBox(height: 28),
          _RevenueCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── Welcome Header ───────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat Datang! 🌿',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dashboard SeiCycle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kebun Sei – Sistem Pertanian & Peternakan Terintegrasi Berbasis Nutrisi Berkelanjutan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeaderBadge(
                      icon: Icons.location_on_outlined,
                      label: 'Pakisaji, Malang',
                    ),
                    const SizedBox(width: 8),
                    _HeaderBadge(
                      icon: Icons.area_chart_outlined,
                      label: '±500 m²',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset('lib/assets/logo.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth >= 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 2;
        }
        final childAspectRatio = constraints.maxWidth >= 900
            ? 1.05
            : (constraints.maxWidth >= 600 ? 1.1 : 0.95);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: AppData.dashboardStats.length,
          itemBuilder: (context, i) =>
              StatCard(data: AppData.dashboardStats[i]),
        );
      },
    );
  }
}

// ─── Activity Timeline ────────────────────────────────────────────────────────

class _ActivityTimeline extends StatelessWidget {
  static const _activities = [
    _ActivityItem(
      '06:00',
      'Pakan cacing & pemeriksaan kelembaban media',
      Icons.grass_outlined,
      AppColors.primaryGreen,
      true,
    ),
    _ActivityItem(
      '06:30',
      'Pakan pagi 150 ekor ayam – 7,5 kg dedak+talas',
      Icons.egg_alt_outlined,
      AppColors.warning,
      true,
    ),
    _ActivityItem(
      '07:00',
      'Pakan lele – 2,5 kg maggot segar, cek air bioflok',
      Icons.water_drop_outlined,
      AppColors.info,
      true,
    ),
    _ActivityItem(
      '09:00',
      'Pemindahan batch maggot BSF hari ke-12 ke wadah panen',
      Icons.bug_report_outlined,
      AppColors.accentLightGreen,
      false,
    ),
    _ActivityItem(
      '16:00',
      'Pakan sore ayam & pencatatan telur harian di logbook',
      Icons.edit_note_outlined,
      AppColors.warning,
      false,
    ),
    _ActivityItem(
      '16:30',
      'Pakan sore lele & cek SR kolam',
      Icons.set_meal_outlined,
      AppColors.info,
      false,
    ),
    _ActivityItem(
      '17:00',
      'Siram tanaman dengan air kolam & pupuk kascing cair',
      Icons.eco_outlined,
      AppColors.success,
      false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(_activities.length, (i) {
            final a = _activities[i];
            final isLast = i == _activities.length - 1;
            return _TimelineRow(activity: a, isLast: isLast);
          }),
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String time;
  final String title;
  final IconData icon;
  final Color color;
  final bool done;

  const _ActivityItem(this.time, this.title, this.icon, this.color, this.done);
}

class _TimelineRow extends StatelessWidget {
  final _ActivityItem activity;
  final bool isLast;

  const _TimelineRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 46,
            child: Text(
              activity.time,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: activity.done
                      ? activity.color
                      : activity.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  activity.done ? Icons.check : activity.icon,
                  color: activity.done ? Colors.white : activity.color,
                  size: 14,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.progressBg,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: activity.done
                            ? AppColors.textMuted
                            : AppColors.textDark,
                        decoration: activity.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        fontWeight: activity.done
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (activity.done)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
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

// ─── Revenue Card ─────────────────────────────────────────────────────────────

class _RevenueCard extends StatelessWidget {
  static const _revenueItems = [
    _RevenueItem('Cacing & Kascing', 'Rp 5 jt', 0.25, AppColors.primaryGreen),
    _RevenueItem('Ayam & Telur', 'Rp 5 jt', 0.25, AppColors.warning),
    _RevenueItem('Lele Organik', 'Rp 3 jt', 0.15, AppColors.info),
    _RevenueItem('Maggot BSF', 'Rp 2 jt', 0.10, AppColors.accentLightGreen),
    _RevenueItem('Tanaman Pangan', 'Rp 2 jt', 0.10, AppColors.accentBrown),
    _RevenueItem('Edukasi & Workshop', 'Rp 3 jt', 0.15, AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rincian Omset Bulanan – Rp 20 jt',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Proyeksi periode Juni–Agustus 2025: Rp 96 jt',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ..._revenueItems.map((item) => _RevenueRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _RevenueItem {
  final String label;
  final String amount;
  final double portion;
  final Color color;

  const _RevenueItem(this.label, this.amount, this.portion, this.color);
}

class _RevenueRow extends StatelessWidget {
  final _RevenueItem item;

  const _RevenueRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            ),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.portion,
                backgroundColor: item.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(item.color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              item.amount,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                color: item.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
