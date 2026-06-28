import 'package:flutter/material.dart';

import '../../../core/constants/farm_modules.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/widgets/async_state_widgets.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../theme/app_theme.dart';
import '../../profile/models/app_user.dart';
import '../models/recommendation_model.dart';
import '../services/recommendation_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({required this.profile, super.key});

  final AppUser profile;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  late final RecommendationService _service;
  late Future<List<RecommendationModel>> _future;

  @override
  void initState() {
    super.initState();
    _service = RecommendationService();
    _load();
  }

  void _load() {
    _future = _service.generate(
      includeFinance: widget.profile.canViewFinanceDashboard,
    );
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: 'AI Recommendation',
      subtitle:
          'Rekomendasi rule-based dari logbook, stok, jadwal, dan keuangan.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => setState(_load),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
      child: FutureBuilder<List<RecommendationModel>>(
        future: _future,
        builder: (context, snapshot) {
          final state = asyncSnapshotState(snapshot);
          if (state != null) return state;

          final recommendations = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: recommendations.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyState(
                        title: 'Belum ada rekomendasi',
                        message:
                            'Data operasional belum cukup untuk menghasilkan rekomendasi.',
                        icon: Icons.psychology_alt_outlined,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: recommendations.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) return const _RecommendationNotice();
                      return _RecommendationCard(
                        recommendation: recommendations[index - 1],
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _RecommendationNotice extends StatelessWidget {
  const _RecommendationNotice();

  @override
  Widget build(BuildContext context) {
    return const InlineMessage(
      icon: Icons.auto_awesome_outlined,
      color: AppColors.info,
      message:
          'Tahap awal ini memakai aturan sederhana di aplikasi, bukan machine learning cloud atau API AI berbayar.',
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final RecommendationModel recommendation;

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(recommendation.priority);
    return AppCard(
      borderColor: color.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBox(icon: _typeIcon(recommendation.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: _priorityLabel(recommendation.priority),
                      color: color,
                    ),
                    StatusBadge(
                      label: _typeLabel(recommendation.type),
                      color: AppColors.primaryGreen,
                    ),
                    if (recommendation.moduleType != null)
                      StatusBadge(
                        label: FarmModules.nameOf(recommendation.moduleType!),
                        color: AppColors.info,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  recommendation.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMedium,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _priorityColor(String priority) => switch (priority) {
  'high' => AppColors.error,
  'normal' => AppColors.warning,
  'low' => AppColors.info,
  _ => AppColors.textMuted,
};

String _priorityLabel(String priority) => switch (priority) {
  'high' => 'Prioritas tinggi',
  'normal' => 'Prioritas normal',
  'low' => 'Prioritas rendah',
  _ => priority,
};

String _typeLabel(String type) => switch (type) {
  'harvest_prediction' => 'Prediksi panen',
  'productivity' => 'Produktivitas',
  'inventory' => 'Stok',
  'schedule' => 'Jadwal',
  'logbook' => 'Logbook',
  'finance' => 'Keuangan',
  _ => 'Insight',
};

IconData _typeIcon(String type) => switch (type) {
  'harvest_prediction' => Icons.agriculture_outlined,
  'productivity' => Icons.insights_outlined,
  'inventory' => Icons.inventory_2_outlined,
  'schedule' => Icons.event_busy_outlined,
  'logbook' => Icons.menu_book_outlined,
  'finance' => Icons.account_balance_wallet_outlined,
  _ => Icons.psychology_alt_outlined,
};
