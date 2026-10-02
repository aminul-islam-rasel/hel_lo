import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/text_styles.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('About Hel Lo', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.floating,
                ),
                child: const Icon(Icons.forum_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Hel Lo Messenger', style: AppTextStyles.headlineLarge(context).copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Version 2.0.0 (Original Redesign)', style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Hel Lo is a modern, high-end communication platform built for secure messaging, HD WebRTC calling, and real-time social connections.',
                style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant).copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
