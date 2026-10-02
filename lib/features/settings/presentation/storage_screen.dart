import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Storage and Data', style: AppTextStyles.headlineLarge(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Used Storage', style: AppTextStyles.titleMedium(context)),
                      Text('1.2 GB / 64 GB', style: AppTextStyles.titleMedium(context).copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: 0.25,
                      minHeight: 10,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ListTile(
            leading: const Icon(Icons.folder_rounded, color: AppColors.primary),
            title: Text('Manage Storage', style: AppTextStyles.titleMedium(context)),
            subtitle: Text('Review and cleanup items larger than 5 MB', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.wifi_rounded, color: AppColors.primary),
            title: Text('Network Usage', style: AppTextStyles.titleMedium(context)),
            subtitle: Text('Sent: 245 MB • Received: 890 MB', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
