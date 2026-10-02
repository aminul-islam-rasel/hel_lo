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
import '../../../core/utils/conversation_utils.dart';
import '../../calls/presentation/providers/call_provider.dart';
import '../../calls/domain/entities/call.dart';
import '../../auth/presentation/auth_controller.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  void _startCall(BuildContext context, WidgetRef ref, String name, String? photo, CallType type) {
    context.push('/calls/outgoing', extra: {
      'receiverId': userId,
      'receiverName': name,
      'receiverPhoto': photo,
      'callType': type,
    });
    ref.read(callProvider.notifier).startCall(
      receiverId: userId,
      receiverName: name,
      receiverPhoto: photo,
      type: type,
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || userId.isEmpty) return;

    final conversationId = ConversationUtils.generateConversationId(currentUserId, userId);
    final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
    final convDoc = await convRef.get();

    if (!convDoc.exists) {
      await convRef.set({
        'conversationId': conversationId,
        'memberIds': [currentUserId, userId],
        'status': 'pending',
        'requestedBy': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    if (context.mounted) {
      context.push('/chat/$conversationId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserAsync = ref.watch(currentUserStreamProvider);
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final blockedList = currentUserAsync.value?.blockedUserIds ?? [];
    final isBlocked = blockedList.contains(userId);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final name = userData?['displayName'] ?? 'Hel Lo User';
        final phone = userData?['phoneNumber'] ?? 'No phone provided';
        final about = userData?['about'] ?? 'Hey there! I am using Hel Lo.';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 38),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.floating,
                          ),
                          child: const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person_rounded, size: 58, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          name,
                          style: AppTextStyles.headlineLarge(context, color: Colors.white).copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: AppTextStyles.bodyMedium(context, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ABOUT & STATUS',
                            style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(about, style: AppTextStyles.bodyLarge(context).copyWith(height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            boxShadow: AppShadows.floating,
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => _openChat(context),
                            icon: const Icon(Icons.forum_rounded),
                            label: const Text('Start Chat'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                onPressed: () => _startCall(context, ref, name, userData?['profilePhoto'], CallType.audio),
                                icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                                label: const Text('Voice Call'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                                onPressed: () => _startCall(context, ref, name, userData?['profilePhoto'], CallType.video),
                                icon: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                                label: const Text('Video Call'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (currentUserId != null && currentUserId != userId)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isBlocked ? AppColors.primary : AppColors.error,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                                side: BorderSide(color: isBlocked ? AppColors.primary : AppColors.error, width: 1.5),
                              ),
                              onPressed: () async {
                                final authNotifier = ref.read(authControllerProvider.notifier);
                                if (isBlocked) {
                                  await authNotifier.unblockUser(userId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('User unblocked successfully')),
                                    );
                                  }
                                } else {
                                  await authNotifier.blockUser(userId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('User blocked successfully')),
                                    );
                                  }
                                }
                              },
                              icon: Icon(isBlocked ? Icons.check_circle_outline_rounded : Icons.block_rounded),
                              label: Text(isBlocked ? 'Unblock User' : 'Block User'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
