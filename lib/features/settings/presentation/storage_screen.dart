import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/text_styles.dart';

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  void _showStorageManager(BuildContext context) {
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
            Text('Storage Breakdown', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            const ListTile(leading: Icon(Icons.image_rounded, color: AppColors.primary), title: Text('Photos & Media'), trailing: Text('850 MB', style: TextStyle(fontWeight: FontWeight.bold))),
            const ListTile(leading: Icon(Icons.video_collection_rounded, color: AppColors.primary), title: Text('Videos'), trailing: Text('400 MB', style: TextStyle(fontWeight: FontWeight.bold))),
            const ListTile(leading: Icon(Icons.mic_rounded, color: AppColors.primary), title: Text('Voice Messages'), trailing: Text('150 MB', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.floating,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared successfully! 1.4 GB freed up.')),
                    );
                  },
                  child: const Text('Free Up Space (Clear Cache)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Storage & Data', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              boxShadow: AppShadows.lightSubtle,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Used Storage', style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                    Text('1.4 GB / 64 GB', style: AppTextStyles.titleMedium(context).copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: 0.22,
                    minHeight: 12,
                    backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildStorageTile(context, isDark, Icons.folder_rounded, 'Manage Storage', 'Review and cleanup large media items', () => _showStorageManager(context)),
          _buildStorageTile(context, isDark, Icons.wifi_rounded, 'Network Usage', 'Sent: 340 MB • Received: 1.1 GB', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Network stats: 340 MB sent, 1.1 GB received.')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStorageTile(BuildContext context, bool isDark, IconData icon, String title, String subtitle, VoidCallback onTap) {
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
