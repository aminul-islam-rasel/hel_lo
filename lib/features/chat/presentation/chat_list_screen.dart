import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_shimmer_widget.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _showArchived = false;

  void _showChatOptions(BuildContext context, String conversationId, bool isArchived, String otherName) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  otherName,
                  style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: Icon(
                    isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(isArchived ? 'Unarchive Chat' : 'Archive Chat'),
                  onTap: () async {
                    Navigator.pop(context);
                    HapticFeedback.mediumImpact();
                    try {
                      final ref = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
                      if (isArchived) {
                        await ref.update({
                          'archivedBy': FieldValue.arrayRemove([currentUserId])
                        });
                      } else {
                        await ref.update({
                          'archivedBy': FieldValue.arrayUnion([currentUserId])
                        });
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(isArchived ? 'Chat unarchived' : 'Chat archived')),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error toggling archive: $e');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteChat(context, conversationId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteChat(BuildContext context, String conversationId) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? Messages will be removed for you.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              try {
                await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
                  'deletedFor': FieldValue.arrayUnion([currentUserId])
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat deleted')),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting chat: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: _showArchived
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _showArchived = false),
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs + 2),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.lightSubtle,
              ),
              child: Icon(_showArchived ? Icons.archive_rounded : Icons.forum_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showArchived ? 'Archived Chats' : 'Hel Lo',
                  style: AppTextStyles.titleLarge(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _showArchived ? 'Hidden conversations' : 'Stay connected',
                  style: AppTextStyles.caption(
                    context,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: currentUserId == null
          ? Center(
              child: Text('Please log in to view chats', style: AppTextStyles.bodyMedium(context)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .where('memberIds', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 6,
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    itemBuilder: (context, index) => AppShimmerWidget.chatListTile(context),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filter out deleted chats
                final activeDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                  return !deletedFor.contains(currentUserId);
                }).toList();

                final pendingRequests = activeDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'pending' && data['requestedBy'] != currentUserId;
                }).toList();

                // Calculate total archived count across all active docs
                int archivedCount = 0;
                for (var doc in activeDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final archivedBy = List<String>.from(data['archivedBy'] ?? []);
                  if (archivedBy.contains(currentUserId)) {
                    archivedCount++;
                  }
                }

                // If currently showing archived but all were unarchived, return to active chats automatically
                if (_showArchived && archivedCount == 0) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _showArchived = false);
                  });
                }

                final Map<String, QueryDocumentSnapshot> uniqueInboxMap = {};

                for (var doc in activeDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'];
                  final requestedBy = data['requestedBy'];
                  final isPending = status == 'pending' && requestedBy != currentUserId;

                  if (!isPending) {
                    final archivedBy = List<String>.from(data['archivedBy'] ?? []);
                    final isArchived = archivedBy.contains(currentUserId);

                    if (isArchived != _showArchived) {
                      continue;
                    }

                    final memberIds = List<String>.from(data['memberIds'] ?? []);
                    final otherUserId = memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
                    if (otherUserId.isNotEmpty) {
                      if (!uniqueInboxMap.containsKey(otherUserId)) {
                        uniqueInboxMap[otherUserId] = doc;
                      } else {
                        final existingDoc = uniqueInboxMap[otherUserId]!;
                        final existingData = existingDoc.data() as Map<String, dynamic>;
                        final existingTime = (existingData['lastMessageTime'] as Timestamp?) ?? (existingData['updatedAt'] as Timestamp?);
                        final currentTime = (data['lastMessageTime'] as Timestamp?) ?? (data['updatedAt'] as Timestamp?);
                        if (existingTime == null || (currentTime != null && currentTime.compareTo(existingTime) > 0)) {
                          uniqueInboxMap[otherUserId] = doc;
                        }
                      }
                    }
                  }
                }

                final inboxDocs = uniqueInboxMap.values.toList();

                inboxDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  final timeA = (dataA['lastMessageTime'] as Timestamp?) ?? (dataA['updatedAt'] as Timestamp?);
                  final timeB = (dataB['lastMessageTime'] as Timestamp?) ?? (dataB['updatedAt'] as Timestamp?);

                  if (timeA == null && timeB == null) return 0;
                  if (timeA == null) return 1;
                  if (timeB == null) return -1;

                  return timeB.compareTo(timeA);
                });

                return Column(
                  children: [
                    // Quick Search Bar Header Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                      child: InkWell(
                        onTap: () => context.push('/search'),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Search conversations & people...',
                                style: AppTextStyles.bodyMedium(
                                  context,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Archived Toggle Bar
                    if (archivedCount > 0 && !_showArchived)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showArchived = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.archive_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Archived Chats ($archivedCount)',
                                    style: AppTextStyles.titleSmall(context).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Pending Requests Banner
                    if (!_showArchived && pendingRequests.isNotEmpty)
                      InkWell(
                        onTap: () => context.push('/chat/requests'),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.floating,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Message Requests (${pendingRequests.length})',
                                      style: AppTextStyles.titleMedium(context).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to review new chat requests',
                                      style: AppTextStyles.bodySmall(context, color: Colors.white.withValues(alpha: 0.9)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white),
                            ],
                          ),
                        ),
                      ),

                    Expanded(
                      child: inboxDocs.isEmpty
                          ? Center(
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
                                      child: Icon(
                                        _showArchived ? Icons.archive_outlined : Icons.forum_outlined,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    Text(
                                      _showArchived ? 'No Archived Chats' : 'Start a Conversation',
                                      style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      _showArchived
                                          ? 'Archived chats will appear here.'
                                          : 'Connect with someone and begin chatting instantly.',
                                      style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (!_showArchived) ...[
                                      const SizedBox(height: AppSpacing.xxl),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: AppGradients.primary,
                                          borderRadius: BorderRadius.circular(AppRadius.pill),
                                          boxShadow: AppShadows.floating,
                                        ),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                          ),
                                          onPressed: () => context.push('/contacts'),
                                          icon: const Icon(Icons.person_add_rounded),
                                          label: const Text('Find People'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: inboxDocs.length,
                              padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: 80),
                              itemBuilder: (context, index) {
                                final data = inboxDocs[index].data() as Map<String, dynamic>;
                                final conversationId = inboxDocs[index].id;
                                final lastMessage = data['lastMessage'] ?? 'Say hello 👋';
                                final lastTime = (data['lastMessageTime'] as Timestamp?) ?? (data['updatedAt'] as Timestamp?);
                                final memberIds = List<String>.from(data['memberIds'] ?? []);
                                final otherUserId = memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
                                final unreadBy = List<String>.from(data['unreadBy'] ?? []);
                                final isUnread = unreadBy.contains(currentUserId);
                                final archivedBy = List<String>.from(data['archivedBy'] ?? []);
                                final isArchived = archivedBy.contains(currentUserId);

                                return StreamBuilder<DocumentSnapshot>(
                                  stream: otherUserId.isNotEmpty
                                      ? FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots()
                                      : null,
                                  builder: (context, userSnapshot) {
                                    final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                                    final otherName = userData?['displayName'] ?? 'User';
                                    final isOnline = userData?['isOnline'] ?? false;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.xs,
                                      ),
                                      child: Material(
                                        color: isUnread
                                            ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.06))
                                            : (isDark ? AppColors.darkCard : AppColors.lightCard),
                                        borderRadius: BorderRadius.circular(AppRadius.xl),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(AppRadius.xl),
                                          onTap: () => context.push('/chat/$conversationId'),
                                          onLongPress: () {
                                            HapticFeedback.mediumImpact();
                                            _showChatOptions(context, conversationId, isArchived, otherName);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(AppSpacing.md),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(AppRadius.xl),
                                              border: Border.all(
                                                color: isUnread
                                                    ? AppColors.primary.withValues(alpha: 0.3)
                                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Stack(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(2),
                                                      decoration: BoxDecoration(
                                                        gradient: isOnline ? AppGradients.statusRing : null,
                                                        color: isOnline ? null : AppColors.primary.withValues(alpha: 0.15),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const CircleAvatar(
                                                        radius: 26,
                                                        backgroundColor: AppColors.primary,
                                                        child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                                                      ),
                                                    ),
                                                    if (isOnline)
                                                      Positioned(
                                                        bottom: 2,
                                                        right: 2,
                                                        child: Container(
                                                          width: 14,
                                                          height: 14,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.online,
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: theme.scaffoldBackgroundColor,
                                                              width: 2.5,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(width: AppSpacing.md),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              otherName,
                                                              style: AppTextStyles.titleMedium(context).copyWith(
                                                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          if (lastTime != null)
                                                            Text(
                                                              _formatTime(lastTime.toDate()),
                                                              style: AppTextStyles.caption(
                                                                context,
                                                                color: isUnread ? AppColors.primary : null,
                                                              ).copyWith(fontWeight: isUnread ? FontWeight.bold : FontWeight.w500),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          if (!isUnread) ...[
                                                            const Icon(Icons.done_all_rounded, size: 16, color: AppColors.readReceiptBlue),
                                                            const SizedBox(width: 4),
                                                          ],
                                                          Expanded(
                                                            child: Text(
                                                              lastMessage,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: AppTextStyles.bodySmall(
                                                                context,
                                                                color: isUnread
                                                                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                                                                    : theme.colorScheme.onSurfaceVariant,
                                                              ).copyWith(
                                                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                                              ),
                                                            ),
                                                          ),
                                                          if (isUnread)
                                                            Container(
                                                              margin: const EdgeInsets.only(left: AppSpacing.sm),
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                              decoration: BoxDecoration(
                                                                gradient: AppGradients.primary,
                                                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                                              ),
                                                              child: Text(
                                                                'NEW',
                                                                style: AppTextStyles.caption(context, color: Colors.white).copyWith(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}
