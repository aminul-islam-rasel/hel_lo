import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/text_styles.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: AppTextStyles.headlineLarge(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Hel Lo Messenger', style: AppTextStyles.headlineLarge(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('Version 1.0.0 (Pro)', style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Hel Lo is a secure, modern, and high-performance real-time messaging application designed for seamless communication.',
                style: AppTextStyles.bodyMedium(context),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
