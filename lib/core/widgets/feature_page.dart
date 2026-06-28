import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 22,
            compact ? 18 : 22,
            compact ? 14 : 22,
            compact ? 14 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                header,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ),
                ],
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: header),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: actions),
                    ],
                  ],
                ),
              const SizedBox(height: 14),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
