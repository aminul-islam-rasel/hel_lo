import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/text_styles.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Contacts', style: AppTextStyles.headlineLarge(context)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block_rounded, size: 64, color: AppColors.offline),
            const SizedBox(height: AppSpacing.md),
            Text('No blocked contacts', style: AppTextStyles.headlineMedium(context)),
            const SizedBox(height: AppSpacing.xs),
            Text('Blocked contacts will appear here', style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
