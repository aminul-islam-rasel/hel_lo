import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppLoadingSize { small, medium, large }

class AppLoadingWidget extends StatefulWidget {
  final AppLoadingSize size;
  final Color? color;
  final String? message;

  const AppLoadingWidget({
    super.key,
    this.size = AppLoadingSize.medium,
    this.color,
    this.message,
  });

  const AppLoadingWidget.small({
    super.key,
    this.color,
  })  : size = AppLoadingSize.small,
        message = null;

  const AppLoadingWidget.large({
    super.key,
    this.color,
    this.message,
  })  : size = AppLoadingSize.large;

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

class _AppLoadingWidgetState extends State<AppLoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _dimension {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 20.0;
      case AppLoadingSize.medium:
        return 48.0;
      case AppLoadingSize.large:
        return 72.0;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 12.0;
      case AppLoadingSize.medium:
        return 26.0;
      case AppLoadingSize.large:
        return 40.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.primary;

    final indicator = ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: _dimension,
        height: _dimension,
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: activeColor.withOpacity(0.4),
            width: widget.size == AppLoadingSize.small ? 1.5 : 2.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.chat_bubble_rounded,
            size: _iconSize,
            color: activeColor,
          ),
        ),
      ),
    );

    if (widget.message != null && widget.message!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          indicator,
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.message!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return indicator;
  }
}
