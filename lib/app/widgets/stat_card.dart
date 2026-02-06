// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Reusable statistics card widget to avoid duplication across screens.
///
/// Features:
/// - Title, value, optional subtitle.
/// - Leading icon or custom leading.
/// - Custom color/gradient with sensible defaults.
/// - Optional trend percentage (+/-) with directional arrow.
/// - Loading and empty states.
/// - Compact mode and onTap callback.
/// - RTL-friendly layout.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.color,
    this.gradient,
    this.onTap,
    this.loading = false,
    this.empty = false,
    this.trendPercent,
    this.compact = false,
    this.valueTextStyle,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.borderRadius = 14,
    this.padding,
    this.elevation = 0,
  }) : assert(
         leading == null || icon == null,
         'Use either icon or leading, not both',
       );

  /// Primary title of the card.
  final String title;

  /// Main numeric/text value to display.
  final String value;

  /// Optional subtitle (e.g., label like "اليوم" أو "هذا الشهر").
  final String? subtitle;

  /// Optional material icon.
  final IconData? icon;

  /// Optional custom leading widget (if you need more than an icon).
  final Widget? leading;

  /// Optional trailing widget (e.g., small change chip at row end).
  final Widget? trailing;

  /// Solid color fallback if no gradient is supplied.
  final Color? color;

  /// Optional gradient background.
  final Gradient? gradient;

  /// Tap interaction.
  final VoidCallback? onTap;

  /// Loading state.
  final bool loading;

  /// Empty state.
  final bool empty;

  /// Trend percent (positive/negative). Example: 12.5 means +12.5%.
  final double? trendPercent;

  /// Compact mode reduces paddings and font sizes.
  final bool compact;

  /// Optional text styles overrides.
  final TextStyle? valueTextStyle;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;

  /// Border radius.
  final double borderRadius;

  /// Content padding.
  final EdgeInsetsGeometry? padding;

  /// Card elevation (for Material).
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final bgDecoration = BoxDecoration(
      color: gradient == null ? (color ?? theme.colorScheme.surface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
    );

    final content = _buildContent(context, isRTL);
    final child = Container(
      decoration: bgDecoration,
      padding: padding ?? EdgeInsets.all(compact ? 12 : 16),
      child: content,
    );

    final material = Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );

    return material;
  }

  Widget _buildContent(BuildContext context, bool isRTL) {
    if (loading) {
      return _buildLoading(context);
    }
    if (empty) {
      return _buildEmpty(context);
    }

    final theme = Theme.of(context);
    final titleStyle =
        titleTextStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        );
    final valueStyle =
        valueTextStyle ??
        theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        );
    final subtitleStyle =
        subtitleTextStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        );

    final leadingWidget =
        leading ??
        (icon != null ? _IconBadge(icon: icon!, compact: compact) : null);

    final trendWidget = (trendPercent != null)
        ? _TrendBadge(percent: trendPercent!, compact: compact)
        : const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leadingWidget != null) leadingWidget,
        if (leadingWidget != null) SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: isRTL
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: compact ? 6 : 8),
              Row(
                mainAxisAlignment: isRTL
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: valueStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  trendWidget,
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: compact ? 6 : 8),
                Text(
                  subtitle!,
                  style: subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withOpacity(0.1);
    final highlight = Theme.of(context).colorScheme.onSurface.withOpacity(0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShimmerBox(height: 14, width: 80, base: base, highlight: highlight),
        const SizedBox(height: 12),
        _ShimmerBox(height: 28, width: 120, base: base, highlight: highlight),
        const SizedBox(height: 10),
        _ShimmerBox(height: 12, width: 100, base: base, highlight: highlight),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'لا توجد بيانات',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.compact});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: theme.colorScheme.primary,
        size: compact ? 18 : 22,
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.percent, required this.compact});

  final double percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    final positive = percent >= 0;
    final color = positive ? Colors.green : Colors.red;
    final icon = positive ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 12 : 14),
          const SizedBox(width: 4),
          Text(
            '${percent.abs().toStringAsFixed(1)}%'.replaceAll('-', ''),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.height,
    required this.width,
    required this.base,
    required this.highlight,
  });
  final double height;
  final double width;
  final Color base;
  final Color highlight;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: [widget.base, widget.highlight, widget.base],
              stops: const [0.1, 0.3, 0.6],
            ),
          ),
        );
      },
    );
  }
}
