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
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendCustomMessage(String text, {String type = 'text'}) async {
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

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

      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.conversationId)
          .set({
        'lastMessage': type == 'text' ? text : '[$type shared]',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Message sent successfully
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendCustomMessage(text, type: 'text');
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Share Content', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(Icons.image_rounded, 'Gallery', Colors.purple, () {
                  Navigator.pop(context);
                  _sendCustomMessage('📷 Image shared', type: 'image');
                }),
                _buildAttachmentOption(Icons.camera_alt_rounded, 'Camera', Colors.pink, () {
                  Navigator.pop(context);
                  _sendCustomMessage('📸 Photo taken', type: 'image');
                }),
                _buildAttachmentOption(Icons.insert_drive_file_rounded, 'Document', Colors.indigo, () {
                  Navigator.pop(context);
                  _sendCustomMessage('📄 Document.pdf', type: 'document');
                }),
                _buildAttachmentOption(Icons.location_on_rounded, 'Location', Colors.green, () {
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

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
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

        return StreamBuilder<DocumentSnapshot>(
          stream: otherUserId.isNotEmpty
              ? FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots()
              : null,
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final otherName = userData?['displayName'] ?? 'Hel Lo User';
            final isOnline = userData?['isOnline'] ?? false;

            return Scaffold(
              appBar: AppBar(
                titleSpacing: 0,
                title: InkWell(
                  onTap: () => context.push('/profile/$otherUserId'),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 22),
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.online,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(otherName, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: AppTextStyles.caption(context, color: isOnline ? AppColors.online : AppColors.offline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                    onPressed: () async {
                      if (otherUserId.isEmpty) return;
                      await ref.read(callProvider.notifier).startCall(
                        receiverId: otherUserId,
                        receiverName: otherName,
                        type: CallType.video,
                      );
                      if (context.mounted) {
                        context.push('/calls/outgoing', extra: {
                          'receiverId': otherUserId,
                          'receiverName': otherName,
                          'callType': CallType.video,
                        });
                      }
                    },
                    tooltip: 'Video Call',
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                    onPressed: () async {
                      if (otherUserId.isEmpty) return;
                      await ref.read(callProvider.notifier).startCall(
                        receiverId: otherUserId,
                        receiverName: otherName,
                        type: CallType.audio,
                      );
                      if (context.mounted) {
                        context.push('/calls/outgoing', extra: {
                          'receiverId': otherUserId,
                          'receiverName': otherName,
                          'callType': CallType.audio,
                        });
                      }
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
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(widget.conversationId)
                          .collection('messages')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
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
                                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: Colors.white),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text('No messages yet', style: AppTextStyles.headlineMedium(context)),
                                const SizedBox(height: AppSpacing.xs),
                                Text('Send a message to start conversation', style: AppTextStyles.bodyMedium(context, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                            final data = docs[index].data() as Map<String, dynamic>;
                            final isMe = data['senderId'] == currentUserId;
                            final text = data['text'] ?? '';
                            final timestamp = data['createdAt'] as Timestamp?;
                            final timeStr = timestamp != null
                                ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
                                : 'Just now';

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? (isDark ? AppColors.darkSenderBubble : AppColors.lightSenderBubble)
                                      : (isDark ? AppColors.darkReceiverBubble : AppColors.lightReceiverBubble),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(AppRadius.lg),
                                    topRight: const Radius.circular(AppRadius.lg),
                                    bottomLeft: Radius.circular(isMe ? AppRadius.lg : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : AppRadius.lg),
                                  ),
                                  boxShadow: AppShadows.lightSubtle,
                                  border: Border.all(
                                    color: isMe
                                        ? Colors.transparent
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      text,
                                      style: AppTextStyles.bodyLarge(context).copyWith(
                                        color: isMe && !isDark ? AppColors.lightTextPrimary : null,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          timeStr,
                                          style: AppTextStyles.caption(
                                            context,
                                            color: isMe && !isDark ? AppColors.lightTextSecondary : null,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: AppSpacing.xxs),
                                          const Icon(Icons.done_all_rounded, size: 14, color: AppColors.readReceiptBlue),
                                        ],
                                      ],
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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: AppShadows.lightSubtle,
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.primary),
                            onPressed: () {},
                            tooltip: 'Emoji',
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: TextField(
                                controller: _messageController,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
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
                          const SizedBox(width: AppSpacing.xs),
                          IconButton(
                            icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                            onPressed: _showAttachmentBottomSheet,
                            tooltip: 'Attach',
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.lightSubtle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              onPressed: _isSending ? null : _sendMessage,
                              tooltip: 'Send',
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
