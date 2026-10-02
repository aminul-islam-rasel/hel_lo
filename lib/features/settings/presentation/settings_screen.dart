import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headlineLarge(context)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading settings...')),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final displayName = user?.displayName ?? 'Hel Lo User';
          final about = user?.about ?? 'Available';

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                leading: const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded, size: 36, color: Colors.white),
                ),
                title: Text(displayName, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text(about, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/settings/profile'),
              ),
              const Divider(height: AppSpacing.xl),
              _buildSectionHeader(context, 'Account & Privacy'),
              _buildSettingsTile(context, Icons.key_rounded, 'Account', 'Security notifications, change number', () => context.push('/settings/profile')),
              _buildSettingsTile(context, Icons.lock_outline_rounded, 'Privacy', 'Block contacts, disappearing messages', () => context.push('/settings/privacy')),
              _buildSettingsTile(context, Icons.block_rounded, 'Blocked Users', 'Manage blocked contacts', () => context.push('/settings/blocked')),
              const Divider(height: AppSpacing.xl),
              _buildSectionHeader(context, 'App & Data'),
              _buildSettingsTile(context, Icons.notifications_outlined, 'Notifications', 'Message, group & call tones', () => context.push('/settings/notifications')),
              _buildSettingsTile(context, Icons.storage_rounded, 'Storage and Data', 'Network usage, auto-download', () => context.push('/settings/storage')),
              const Divider(height: AppSpacing.xl),
              _buildSectionHeader(context, 'Support & About'),
              _buildSettingsTile(context, Icons.help_outline_rounded, 'Help', 'Help center, contact us, privacy policy', () => context.push('/settings/help')),
              _buildSettingsTile(context, Icons.info_outline_rounded, 'About', 'App version and license information', () => context.push('/settings/about')),
              const Divider(height: AppSpacing.xl),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                ),
                title: Text('Logout', style: AppTextStyles.titleMedium(context).copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                subtitle: Text('Sign out of your account', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xxs),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
