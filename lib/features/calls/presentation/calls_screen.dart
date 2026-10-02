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
import '../domain/entities/call.dart';
import 'providers/call_provider.dart';

final callFilterProvider = StateProvider.autoDispose<int>((ref) => 0);

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedFilter = ref.watch(callFilterProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Calls',
          style: AppTextStyles.headlineLarge(context).copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: currentUserId == null
          ? Center(child: Text('Please log in', style: AppTextStyles.bodyMedium(context)))
          : Column(
              children: [
                // Filter Tabs (All vs Missed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      _buildFilterChip(context, ref, 0, 'All Calls', selectedFilter == 0),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip(context, ref, 1, 'Missed', selectedFilter == 1),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('calls').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: AppLoadingWidget(message: 'Loading call log...'));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading call history', style: AppTextStyles.bodyMedium(context, color: AppColors.error)),
                        );
                      }

                      final allDocs = snapshot.data?.docs ?? [];
                      
                      var docs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final participants = List<String>.from(data['participants'] ?? []);
                        final callerId = data['callerId'] ?? '';
                        final receiverId = data['receiverId'] ?? '';
                        return participants.contains(currentUserId) || callerId == currentUserId || receiverId == currentUserId;
                      }).toList();

                      if (selectedFilter == 1) {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['status'];
                          final receiverId = data['receiverId'];
                          return (status == 'missed' || status == 'rejected') && receiverId == currentUserId;
                        }).toList();
                      }

                      docs.sort((a, b) {
                        final aTime = ((a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                        final bTime = ((b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
                        return bTime.compareTo(aTime);
                      });

                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xxl + 8),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: AppShadows.floating,
                                  ),
                                  child: const Icon(Icons.phone_missed_rounded, size: 60, color: Colors.white),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  selectedFilter == 1 ? 'No Missed Calls' : 'No Recent Calls',
                                  style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Your call history will appear here in real-time.',
                                  style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 80),
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final callerId = data['callerId'] ?? '';
                          final isOutgoing = callerId == currentUserId;
                          
                          final displayName = isOutgoing ? (data['receiverName'] ?? 'Hel Lo User') : (data['callerName'] ?? 'Hel Lo User');
                          final targetId = isOutgoing ? (data['receiverId'] ?? '') : callerId;
                          final targetPhoto = isOutgoing ? data['receiverPhoto'] : data['callerPhoto'];
                          final isVideo = data['type'] == 'video';
                          final status = data['status'];
                          final isMissed = (status == 'missed' || status == 'rejected') && !isOutgoing;

                          final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
                          final timeStr = timestamp != null
                              ? '${timestamp.day}/${timestamp.month} · ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                              : 'Just now';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
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
                                        Text(
                                          displayName,
                                          style: AppTextStyles.titleMedium(context).copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isMissed ? AppColors.error : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded,
                                              size: 15,
                                              color: isMissed
                                                  ? AppColors.error
                                                  : (isOutgoing ? AppColors.primary : AppColors.success),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isVideo ? 'Video Call' : 'Voice Call',
                                              style: AppTextStyles.caption(context, color: theme.colorScheme.onSurfaceVariant).copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            Text(' · ', style: AppTextStyles.caption(context)),
                                            Text(
                                              timeStr,
                                              style: AppTextStyles.caption(context, color: theme.colorScheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (targetId.isEmpty) return;
                                      final callType = isVideo ? CallType.video : CallType.audio;
                                      context.push('/calls/outgoing', extra: {
                                        'receiverId': targetId,
                                        'receiverName': displayName,
                                        'receiverPhoto': targetPhoto,
                                        'callType': callType,
                                      });
                                      ref.read(callProvider.notifier).startCall(
                                        receiverId: targetId,
                                        receiverName: displayName,
                                        receiverPhoto: targetPhoto,
                                        type: callType,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, int index, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(callFilterProvider.notifier).state = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primary : null,
          color: isSelected ? null : AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
