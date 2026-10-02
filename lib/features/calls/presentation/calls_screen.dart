import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Calls', style: AppTextStyles.headlineLarge(context)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_rounded, size: 20, color: AppColors.primary),
            ),
            onPressed: () => context.push('/calls/incoming'),
            tooltip: 'Simulate Incoming Call',
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: currentUserId == null
          ? Center(child: Text('Please log in', style: AppTextStyles.bodyMedium(context)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('calls')
                  .where('participants', arrayContains: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingWidget(message: 'Loading calls...'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.floating,
                            ),
                            child: const Icon(Icons.phone_missed_rounded, size: 56, color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('No recent calls', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Calls you make or receive will appear here', style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  separatorBuilder: (context, index) => const Divider(indent: 84, height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final callerName = data['callerName'] ?? 'Hel Lo User';
                    final isOutgoing = data['callerId'] == currentUserId;
                    final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
                    final timeStr = timestamp != null
                        ? 'Today, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                        : 'Just now';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                      leading: const CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                      ),
                      title: Text(callerName, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Row(
                        children: [
                          Icon(
                            isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
                            size: 16,
                            color: isOutgoing ? AppColors.primary : AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(timeStr, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_rounded, color: AppColors.primary, size: 20),
                        ),
                        onPressed: () => context.push('/calls/active'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
