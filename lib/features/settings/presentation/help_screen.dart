import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/text_styles.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help', style: AppTextStyles.headlineLarge(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          ListTile(
            leading: const Icon(Icons.help_center_rounded, color: AppColors.primary),
            title: Text('Help Center', style: AppTextStyles.titleMedium(context)),
            subtitle: const Text('Get answers to common questions'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.contact_support_rounded, color: AppColors.primary),
            title: Text('Contact Us', style: AppTextStyles.titleMedium(context)),
            subtitle: const Text('Reach out to our support team'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded, color: AppColors.primary),
            title: Text('Terms and Privacy Policy', style: AppTextStyles.titleMedium(context)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
