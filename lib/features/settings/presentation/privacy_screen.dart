import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  void _showPrivacyPicker(BuildContext context, WidgetRef ref, String settingKey, String label, String currentVal, Map<String, dynamic> settings) {
    final options = ['Everyone', 'My Contacts', 'Nobody'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select $label Visibility', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            ...options.map((opt) => ListTile(
                  title: Text(opt, style: AppTextStyles.titleMedium(context)),
                  trailing: currentVal.toLowerCase() == opt.toLowerCase() ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                  onTap: () async {
                    Navigator.pop(context);
                    final newSettings = Map<String, dynamic>.from(settings);
                    newSettings[settingKey] = opt;
                    await ref.read(authControllerProvider.notifier).updatePrivacySettings(newSettings);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$label visibility updated to $opt')),
                      );
                    }
                  },
                )),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy & Security', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading privacy settings...')),
        error: (err, _) => Center(child: Text('Error loading privacy: $err')),
        data: (user) {
          final settings = user?.privacySettings ?? {};
          final readReceipts = settings['readReceipts'] as bool? ?? true;
          final lastSeenVal = settings['lastSeen']?.toString() ?? 'Everyone';
          final profilePhotoVal = settings['profilePhoto']?.toString() ?? 'Everyone';
          final aboutVal = settings['about']?.toString() ?? 'Everyone';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                child: Text('WHO CAN SEE MY INFO', style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildPrivacyCard(context, isDark, ref, 'lastSeen', 'Last Seen', lastSeenVal, settings),
              const SizedBox(height: AppSpacing.sm),
              _buildPrivacyCard(context, isDark, ref, 'profilePhoto', 'Profile Photo', profilePhotoVal, settings),
              const SizedBox(height: AppSpacing.sm),
              _buildPrivacyCard(context, isDark, ref, 'about', 'About', aboutVal, settings),
              const SizedBox(height: AppSpacing.xl),
              Material(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  title: Text('Read Receipts', style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text('If turned off, you won\'t send or receive read receipts.', style: AppTextStyles.bodySmall(context)),
                  value: readReceipts,
                  onChanged: (val) {
                    final newSettings = Map<String, dynamic>.from(settings);
                    newSettings['readReceipts'] = val;
                    ref.read(authControllerProvider.notifier).updatePrivacySettings(newSettings);
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrivacyCard(BuildContext context, bool isDark, WidgetRef ref, String settingKey, String title, String subtitle, Map<String, dynamic> settings) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        title: Text(title, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall(context)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        onTap: () => _showPrivacyPicker(context, ref, settingKey, title, subtitle, settings),
      ),
    );
  }
}
