import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  void _showHelpModal(BuildContext context, String title, String content) {
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
            Text(title, style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            Text(content, style: AppTextStyles.bodyLarge(context).copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help Center', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildHelpTile(
            context,
            isDark,
            Icons.help_center_rounded,
            'Help Center & FAQs',
            'Get answers to common questions',
            () => _showHelpModal(
              context,
              'Help Center & FAQs',
              'Welcome to Hel Lo Help Center.\n\n• How to chat: Tap on Contacts to find registered users and start messaging.\n• Voice & Video Calls: Use the call buttons inside any chat or calls tab.\n• Privacy: Control who sees your profile in Settings > Privacy & Security.',
            ),
          ),
          _buildHelpTile(
            context,
            isDark,
            Icons.contact_support_rounded,
            'Contact Support',
            'Reach out to our engineering team',
            () => _showHelpModal(
              context,
              'Contact Support',
              'Need assistance? Our support team is available 24/7.\n\nEmail: support@helloapp.com\nTelegram: @HelloSupport',
            ),
          ),
          _buildHelpTile(
            context,
            isDark,
            Icons.privacy_tip_rounded,
            'Terms & Privacy Policy',
            'Read legal policies and security guidelines',
            () => _showHelpModal(
              context,
              'Terms & Privacy Policy',
              'Hel Lo respects your privacy. All messages are encrypted end-to-end. By using Hel Lo, you agree to our community standards and safety protocols.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTile(BuildContext context, bool isDark, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(title, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall(context)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          onTap: onTap,
        ),
      ),
    );
  }
}
