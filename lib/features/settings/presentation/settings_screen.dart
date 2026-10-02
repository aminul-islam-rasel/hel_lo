import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Settings',
          style: AppTextStyles.headlineLarge(context).copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading settings...')),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final displayName = user?.displayName ?? 'Hel Lo User';
          final about = user?.about ?? 'Hey there! I am using Hel Lo.';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: InkWell(
                  onTap: () => context.push('/settings/profile'),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person_rounded, size: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              about,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                        ),
                        onPressed: () => context.push('/settings/profile'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(context, 'Account & Security'),
              const SizedBox(height: AppSpacing.xs),
              _buildSettingsTile(context, Icons.person_outline_rounded, 'Edit Profile', 'Change name, username and bio', () => context.push('/settings/profile')),
              _buildSettingsTile(context, Icons.lock_outline_rounded, 'Privacy & Security', 'Block contacts, privacy rules', () => context.push('/settings/privacy')),
              _buildSettingsTile(context, Icons.block_rounded, 'Blocked Users', 'Manage blocked list', () => context.push('/settings/blocked')),

              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(context, 'Preferences'),
              const SizedBox(height: AppSpacing.xs),
              _buildSettingsTile(context, Icons.notifications_outlined, 'Notifications', 'Message and call alert tones', () => context.push('/settings/notifications')),
              _buildSettingsTile(context, Icons.data_usage_rounded, 'Storage & Network', 'Usage details and media download', () => context.push('/settings/storage')),

              const SizedBox(height: AppSpacing.xl),
              _buildSectionHeader(context, 'Support & App'),
              const SizedBox(height: AppSpacing.xs),
              _buildSettingsTile(context, Icons.help_outline_rounded, 'Help Center', 'FAQs and customer support', () => context.push('/settings/help')),
              _buildSettingsTile(context, Icons.info_outline_rounded, 'About Hel Lo', 'Version, credits, and terms', () => context.push('/settings/about')),

              const SizedBox(height: AppSpacing.xl),
              Material(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  ),
                  title: Text('Logout', style: AppTextStyles.titleMedium(context).copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                  subtitle: Text('Sign out from this device', style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xxs),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
          onTap: onTap,
        ),
      ),
    );
  }
}
