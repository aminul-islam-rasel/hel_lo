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

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  Future<void> _startCall(BuildContext context, WidgetRef ref, String name, String? photo, CallType type) async {
    await ref.read(callProvider.notifier).startCall(
      receiverId: userId,
      receiverName: name,
      receiverPhoto: photo,
      type: type,
    );
    if (context.mounted) {
      context.push('/calls/outgoing', extra: {
        'receiverId': userId,
        'receiverName': name,
        'receiverPhoto': photo,
        'callType': type,
      });
    }
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
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppGradients.primary,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.floating,
                          ),
                          child: const CircleAvatar(
                            radius: 54,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person_rounded, size: 64, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          name,
                          style: AppTextStyles.headlineLarge(context, color: Colors.white).copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
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
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ABOUT & STATUS',
                              style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(about, style: AppTextStyles.bodyLarge(context).copyWith(height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onPressed: () => _openChat(context),
                                icon: const Icon(Icons.chat_rounded),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
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
                                label: const Text('Audio Call'),
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
