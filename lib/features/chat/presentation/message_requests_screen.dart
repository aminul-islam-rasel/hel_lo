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

class MessageRequestsScreen extends ConsumerWidget {
  const MessageRequestsScreen({super.key});

  Future<void> _acceptRequest(BuildContext context, String conversationId) async {
    try {
      await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _declineRequest(BuildContext context, String conversationId) async {
    try {
      await FirebaseFirestore.instance.collection('conversations').doc(conversationId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message request declined')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Message Requests', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22)),
      ),
      body: currentUserId == null
          ? Center(child: Text('Please log in', style: AppTextStyles.bodyMedium(context)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .where('memberIds', arrayContains: currentUserId)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingWidget(message: 'Loading requests...'));
                }

                final docs = snapshot.data?.docs ?? [];
                // Filter only requests where current user is NOT the one who requested
                final incomingRequests = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['requestedBy'] != currentUserId;
                }).toList();

                if (incomingRequests.isEmpty) {
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
                            child: const Icon(Icons.mark_email_unread_rounded, size: 56, color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('No Message Requests', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('New chat requests from people you don\'t know yet will appear here.', style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: incomingRequests.length,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final data = incomingRequests[index].data() as Map<String, dynamic>;
                    final conversationId = incomingRequests[index].id;
                    final requestedBy = data['requestedBy'] ?? '';
                    final lastMessage = data['lastMessage'] ?? 'Wants to chat with you 👋';

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(requestedBy).snapshots(),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                        final senderName = userData?['displayName'] ?? 'Unknown User';
                        final senderPhone = userData?['phoneNumber'] ?? '';

                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            boxShadow: AppShadows.lightSubtle,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primary,
                                    child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(senderName, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                                        if (senderPhone.isNotEmpty)
                                          Text(senderPhone, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Text(
                                  '"$lastMessage"',
                                  style: AppTextStyles.bodyMedium(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: const BorderSide(color: AppColors.error),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                                      ),
                                      onPressed: () => _declineRequest(context, conversationId),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                                      ),
                                      onPressed: () => _acceptRequest(context, conversationId),
                                      child: const Text('Accept'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
