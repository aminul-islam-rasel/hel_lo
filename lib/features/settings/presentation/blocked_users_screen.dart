import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';
import '../../auth/presentation/auth_controller.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Contacts', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: userAsync.when(
        loading: () => const Center(child: AppLoadingWidget(message: 'Loading blocked users...')),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          final blockedIds = user?.blockedUserIds ?? [];

          if (blockedIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.floating,
                      ),
                      child: const Icon(Icons.block_rounded, size: 56, color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('No Blocked Contacts', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Blocked users will appear here and will not be able to message or call you.',
                      style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: blockedIds.length,
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemBuilder: (context, index) {
              final blockedUid = blockedIds[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(blockedUid).snapshots(),
                builder: (context, snapshot) {
                  final userData = snapshot.data?.data() as Map<String, dynamic>?;
                  final name = userData?['displayName'] ?? 'Blocked User';
                  final phone = userData?['phoneNumber'] ?? '';

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
                        leading: const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
                        ),
                        title: Text(name, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                        subtitle: phone.isNotEmpty ? Text(phone, style: AppTextStyles.bodySmall(context)) : null,
                        trailing: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          ),
                          onPressed: () async {
                            await ref.read(authControllerProvider.notifier).unblockUser(blockedUid);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User unblocked successfully')),
                              );
                            }
                          },
                          child: const Text('Unblock'),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
