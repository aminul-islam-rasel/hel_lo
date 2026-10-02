import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.headlineLarge(context)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading notification settings...')),
        error: (err, _) => Center(child: Text('Error loading notification settings: $err')),
        data: (user) {
          final settings = user?.notificationSettings ?? {};
          final sound = settings['sound'] as bool? ?? true;
          final vibrate = settings['vibrate'] as bool? ?? true;
          final preview = settings['preview'] as bool? ?? true;

          void updateSetting(String key, bool value) {
            final newSettings = Map<String, dynamic>.from(settings);
            newSettings[key] = value;
            ref.read(authControllerProvider.notifier).updateNotificationSettings(newSettings);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              SwitchListTile(
                title: Text('Conversation Tones', style: AppTextStyles.titleMedium(context)),
                subtitle: Text('Play sounds for incoming and outgoing messages.', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                value: sound,
                onChanged: (val) => updateSetting('sound', val),
                activeTrackColor: AppColors.primary,
              ),
              SwitchListTile(
                title: Text('Vibrate', style: AppTextStyles.titleMedium(context)),
                value: vibrate,
                onChanged: (val) => updateSetting('vibrate', val),
                activeTrackColor: AppColors.primary,
              ),
              SwitchListTile(
                title: Text('Message Preview', style: AppTextStyles.titleMedium(context)),
                subtitle: Text('Show message preview inside notifications.', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                value: preview,
                onChanged: (val) => updateSetting('preview', val),
                activeTrackColor: AppColors.primary,
              ),
            ],
          );
        },
      ),
    );
  }
}
