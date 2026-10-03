import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../calls/presentation/providers/call_provider.dart';
import '../../calls/domain/entities/call.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatDetailScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier(false);
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _hasTextNotifier.value = _messageController.text.trim().isNotEmpty;

    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
      'typingUserId': currentUserId,
    }).catchError((_) {});

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
        'typingUserId': null,
      }).catchError((_) {});
    });
  }

  Future<void> _markAsRead() async {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    try {
      await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
        'unreadBy': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _hasTextNotifier.dispose();
    super.dispose();
  }

  Future<void> _sendCustomMessage(String text, {String type = 'text'}) async {
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    try {
      final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final messageRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc();

      final messageData = {
        'messageId': messageRef.id,
        'senderId': currentUserId,
        'type': type,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isEdited': false,
        'readBy': [currentUserId],
        'deliveredTo': [currentUserId],
      };

      await messageRef.set(messageData);

      final convDoc = await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).get();
      final convData = convDoc.data();
      final memberIds = List<String>.from(convData?['memberIds'] ?? []);
      final recipients = memberIds.where((id) => id != currentUserId).toList();

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .set({
        'lastMessage': type == 'text' ? text : '[$type shared]',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'typingUserId': null,
        'unreadBy': recipients,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendCustomMessage(text, type: 'text');
  }

  void _showOptions(BuildContext context, DocumentSnapshot doc) {
    HapticFeedback.mediumImpact();
    final data = doc.data() as Map<String, dynamic>;
    final isDeleted = data['isDeleted'] ?? false;
    if (isDeleted) return;

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
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Message Options', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.lg),
            // Quick Reactions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['👍', '❤️', '😂', '😮', '😢', '🔥'].map((emoji) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _addReaction(doc, emoji);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.push_pin_rounded, color: AppColors.primary),
              title: const Text('Pin Message'),
              onTap: () {
                Navigator.pop(context);
                _pinMessage(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
              title: const Text('Edit Message'),
              onTap: () {
                Navigator.pop(context);
                _editMessage(context, doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Delete Message', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(context, doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReaction(DocumentSnapshot doc, String emoji) async {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    try {
      final data = doc.data() as Map<String, dynamic>;
      final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
      reactions[currentUserId] = emoji;
      await doc.reference.update({'reactions': reactions});
    } catch (e) {
      debugPrint('Error adding reaction: $e');
    }
  }

  Future<void> _pinMessage(DocumentSnapshot doc) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = doc.data() as Map<String, dynamic>;
      final text = data['text'] ?? '';
      await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
        'pinnedMessage': text,
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Message pinned')),
      );
    } catch (e) {
      debugPrint('Error pinning message: $e');
    }
  }

  Future<void> _unpinMessage() async {
    try {
      await FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).update({
        'pinnedMessage': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error unpinning message: $e');
    }
  }

  void _editMessage(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final currentText = data['text'] ?? '';
    final editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Edit message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              Navigator.pop(context);
              if (newText.isEmpty || newText == currentText) return;
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .collection('messages')
                    .doc(doc.id)
                    .update({
                  'text': newText,
                  'isEdited': true,
                });
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to edit message: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message for everyone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .collection('messages')
                    .doc(doc.id)
                    .update({
                  'isDeleted': true,
                  'text': '🚫 This message was deleted',
                });
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to delete message: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentBottomSheet() {
    HapticFeedback.lightImpact();
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
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Share Content', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.image_rounded, 'Gallery', const Color(0xFF8B5CF6), () {
                  Navigator.pop(context);
                  _showMediaPreviewDialog('image');
                }),
                _buildAttachmentOption(Icons.camera_alt_rounded, 'Camera', const Color(0xFFEC4899), () {
                  Navigator.pop(context);
                  _showMediaPreviewDialog('image');
                }),
                _buildAttachmentOption(Icons.insert_drive_file_rounded, 'Document', const Color(0xFF6366F1), () {
                  Navigator.pop(context);
                  _sendCustomMessage('📄 Document.pdf', type: 'document');
                }),
                _buildAttachmentOption(Icons.location_on_rounded, 'Location', const Color(0xFF10B981), () {
                  Navigator.pop(context);
                  _sendCustomMessage('📍 Current Location', type: 'location');
                }),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showMediaPreviewDialog(String type) {
    final captionController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        title: const Text('Rich Media Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Icon(Icons.image_rounded, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: 'Add a caption...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final caption = captionController.text.trim();
              final text = caption.isNotEmpty ? caption : '📷 Photo shared';
              _sendCustomMessage(text, type: type);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.bodySmall(context).copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('conversations').doc(widget.conversationId).snapshots(),
      builder: (context, convSnapshot) {
        final convData = convSnapshot.data?.data() as Map<String, dynamic>?;
        final memberIds = List<String>.from(convData?['memberIds'] ?? []);
        final otherUserId = memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
        final typingUserId = convData?['typingUserId'];
        final isTyping = typingUserId != null && typingUserId != currentUserId;

        return StreamBuilder<DocumentSnapshot>(
          stream: otherUserId.isNotEmpty
              ? FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots()
              : null,
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final otherName = userData?['displayName'] ?? 'User';
            final isOnline = userData?['isOnline'] ?? false;
            final lastSeenTs = userData?['lastSeen'] as Timestamp?;
            final lastSeenStr = lastSeenTs != null
                ? 'Last seen today at ${lastSeenTs.toDate().hour.toString().padLeft(2, '0')}:${lastSeenTs.toDate().minute.toString().padLeft(2, '0')}'
                : 'Offline';

            return Scaffold(
              appBar: AppBar(
                scrolledUnderElevation: 1,
                titleSpacing: 0,
                title: InkWell(
                  onTap: () => context.push('/profile/$otherUserId'),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              gradient: isOnline ? AppGradients.statusRing : null,
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: AppColors.online,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            otherName,
                            style: AppTextStyles.titleMedium(context).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isTyping
                                ? 'typing...'
                                : (isOnline ? 'Online now' : lastSeenStr),
                            style: AppTextStyles.caption(
                              context,
                              color: isTyping ? AppColors.primary : (isOnline ? AppColors.online : AppColors.offline),
                            ).copyWith(fontWeight: (isOnline || isTyping) ? FontWeight.bold : FontWeight.normal),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 18),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (otherUserId.isEmpty) return;
                      context.push('/calls/outgoing', extra: {
                        'receiverId': otherUserId,
                        'receiverName': otherName,
                        'callType': CallType.video,
                      });
                      ref.read(callProvider.notifier).startCall(
                        receiverId: otherUserId,
                        receiverName: otherName,
                        type: CallType.video,
                      );
                    },
                    tooltip: 'Video Call',
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_rounded, color: AppColors.primary, size: 18),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (otherUserId.isEmpty) return;
                      context.push('/calls/outgoing', extra: {
                        'receiverId': otherUserId,
                        'receiverName': otherName,
                        'callType': CallType.audio,
                      });
                      ref.read(callProvider.notifier).startCall(
                        receiverId: otherUserId,
                        receiverName: otherName,
                        type: CallType.audio,
                      );
                    },
                    tooltip: 'Voice Call',
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => context.push('/profile/$otherUserId'),
                    tooltip: 'View Profile',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
              body: Column(
                children: [
                  if (convData?['pinnedMessage'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                      child: Row(
                        children: [
                          const Icon(Icons.push_pin_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pinned Message', style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  convData!['pinnedMessage'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall(context),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: _unpinMessage,
                            tooltip: 'Unpin',
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(widget.conversationId)
                          .collection('messages')
                          .orderBy('createdAt', descending: true)
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: AppLoadingWidget(message: 'Loading messages...'));
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error loading messages', style: AppTextStyles.bodyMedium(context, color: AppColors.error)),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
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
                                  child: const Icon(Icons.forum_outlined, size: 56, color: Colors.white),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text('Start the conversation', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Say hello 👋 to $otherName below', style: AppTextStyles.bodyMedium(context, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final isMe = data['senderId'] == currentUserId;
                            final text = data['text'] ?? '';
                            final isDeleted = data['isDeleted'] ?? false;
                            final isEdited = data['isEdited'] ?? false;
                            final reactions = Map<String, dynamic>.from(data['reactions'] ?? {});
                            final timestamp = data['createdAt'] as Timestamp?;
                            final timeStr = timestamp != null
                                ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                : 'Just now';

                            final hasUrl = text.contains('http://') || text.contains('https://');

                            return GestureDetector(
                              onLongPress: isMe && !isDeleted ? () => _showOptions(context, doc) : null,
                              child: Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isMe && !isDeleted ? AppGradients.primary : null,
                                        color: isMe && !isDeleted
                                            ? null
                                            : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(AppRadius.xl),
                                          topRight: const Radius.circular(AppRadius.xl),
                                          bottomLeft: Radius.circular(isMe ? AppRadius.xl : 4),
                                          bottomRight: Radius.circular(isMe ? 4 : AppRadius.xl),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isMe && !isDeleted
                                                ? AppColors.primary.withValues(alpha: 0.2)
                                                : Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: isMe
                                              ? Colors.transparent
                                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            text,
                                            style: AppTextStyles.bodyLarge(context).copyWith(
                                              color: isDeleted
                                                  ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                                  : (isMe ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                                              fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                              height: 1.35,
                                            ),
                                          ),
                                          if (hasUrl && !isDeleted) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(AppRadius.md),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.link_rounded, size: 18, color: Colors.white70),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Web Link Preview Card',
                                                      style: AppTextStyles.caption(context, color: Colors.white70).copyWith(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isEdited && !isDeleted) ...[
                                                Text(
                                                  'edited · ',
                                                  style: AppTextStyles.caption(
                                                    context,
                                                    color: isMe ? Colors.white.withValues(alpha: 0.7) : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                                  ).copyWith(fontSize: 10),
                                                ),
                                              ],
                                              Text(
                                                timeStr,
                                                style: AppTextStyles.caption(
                                                  context,
                                                  color: isMe ? Colors.white.withValues(alpha: 0.8) : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                                ).copyWith(fontSize: 11),
                                              ),
                                              if (isMe && !isDeleted) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (reactions.isNotEmpty)
                                      Positioned(
                                        bottom: -6,
                                        right: isMe ? 8 : null,
                                        left: isMe ? null : 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkSurface : Colors.white,
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                            boxShadow: AppShadows.floating,
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            reactions.values.join(' '),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
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

                  // Floating Modern Message Composer Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      boxShadow: AppShadows.floating,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 26),
                            onPressed: _showAttachmentBottomSheet,
                            tooltip: 'Share',
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: TextField(
                                controller: _messageController,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Type something...',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.floating,
                            ),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _hasTextNotifier,
                              builder: (context, hasText, child) {
                                return IconButton(
                                  icon: Icon(
                                    hasText ? Icons.send_rounded : Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    if (hasText) {
                                      _sendMessage();
                                    } else {
                                      _sendCustomMessage('🎤 Voice note', type: 'voice');
                                    }
                                  },
                                  tooltip: hasText ? 'Send' : 'Voice Message',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
