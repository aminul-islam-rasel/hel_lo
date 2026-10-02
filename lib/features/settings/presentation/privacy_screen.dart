import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Settings', style: AppTextStyles.headlineLarge(context)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading privacy settings...')),
        error: (err, _) => Center(child: Text('Error loading privacy settings: $err')),
        data: (user) {
          final settings = user?.privacySettings ?? {};
          final readReceipts = settings['readReceipts'] as bool? ?? true;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                child: Text('Who can see my personal info', style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: Text('Last Seen', style: AppTextStyles.titleMedium(context)),
                subtitle: Text(settings['lastSeen']?.toString() ?? 'Everyone', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                onTap: () {},
              ),
              ListTile(
                title: Text('Profile Photo', style: AppTextStyles.titleMedium(context)),
                subtitle: Text(settings['profilePhoto']?.toString() ?? 'Everyone', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                onTap: () {},
              ),
              ListTile(
                title: Text('About', style: AppTextStyles.titleMedium(context)),
                subtitle: Text(settings['about']?.toString() ?? 'Everyone', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                onTap: () {},
              ),
              const Divider(height: AppSpacing.xl),
              SwitchListTile(
                title: Text('Read Receipts', style: AppTextStyles.titleMedium(context)),
                subtitle: Text('If turned off, you won\'t send or receive read receipts.', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                value: readReceipts,
                onChanged: (val) {
                  final newSettings = Map<String, dynamic>.from(settings);
                  newSettings['readReceipts'] = val;
                  ref.read(authControllerProvider.notifier).updatePrivacySettings(newSettings);
                },
                activeTrackColor: AppColors.primary,
              ),
            ],
          );
        },
      ),
    );
  }
}
