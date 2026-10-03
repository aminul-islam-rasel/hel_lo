import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading notification settings...')),
        error: (err, _) => Center(child: Text('Error loading settings: $err')),
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildSwitchCard(context, isDark, 'Conversation Tones', 'Play sounds for incoming & outgoing messages', sound, (val) => updateSetting('sound', val)),
              const SizedBox(height: AppSpacing.sm),
              _buildSwitchCard(context, isDark, 'Vibrate', 'Vibrate phone on alerts', vibrate, (val) => updateSetting('vibrate', val)),
              const SizedBox(height: AppSpacing.sm),
              _buildSwitchCard(context, isDark, 'Message Preview', 'Show message text in notification banners', preview, (val) => updateSetting('preview', val)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchCard(BuildContext context, bool isDark, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        title: Text(title, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall(context)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}
