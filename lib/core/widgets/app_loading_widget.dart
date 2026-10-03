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
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
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
        return 22.0;
      case AppLoadingSize.medium:
        return 52.0;
      case AppLoadingSize.large:
        return 76.0;
    }
  }

  double get _iconSize {
    switch (widget.size) {
      case AppLoadingSize.small:
        return 12.0;
      case AppLoadingSize.medium:
        return 28.0;
      case AppLoadingSize.large:
        return 42.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? AppColors.primary;

    final indicator = Stack(
      alignment: Alignment.center,
      children: [
        RotationTransition(
          turns: _rotationAnimation,
          child: Container(
            width: _dimension,
            height: _dimension,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  activeColor.withValues(alpha: 0.0),
                  activeColor.withValues(alpha: 0.3),
                  activeColor,
                ],
              ),
            ),
          ),
        ),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: _dimension * 0.82,
            height: _dimension * 0.82,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: _iconSize,
                color: activeColor,
              ),
            ),
          ),
        ),
      ],
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
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );
    }

    return indicator;
  }
}
