import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

abstract final class AppSpacing {
  static const double page = 18;
  static const double pageCompact = 14;
  static const double section = 20;
  static const double card = 14;
  static const double gap = 10;
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.card),
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: borderColor ?? Colors.transparent),
    );
    final content = Padding(padding: padding, child: child);

    return Material(
      color: color ?? AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.color,
    super.key,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppIconBox extends StatelessWidget {
  const AppIconBox({
    required this.icon,
    required this.color,
    super.key,
    this.size = 38,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class AppMenuCard extends StatelessWidget {
  const AppMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.color = AppColors.primaryGreen,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          AppIconBox(icon: icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class ResponsiveFormRow extends StatelessWidget {
  const ResponsiveFormRow({
    required this.children,
    super.key,
    this.breakpoint = 460,
    this.spacing = 10,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                SizedBox(width: double.infinity, child: children[index]),
                if (index < children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class InlineMessage extends StatelessWidget {
  const InlineMessage({
    required this.message,
    super.key,
    this.icon = Icons.info_outline,
    this.color = AppColors.info,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMedium),
            ),
          ),
        ],
      ),
    );
  }
}
