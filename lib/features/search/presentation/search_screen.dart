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
import '../../../core/widgets/app_loading_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(String targetUid) async {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || targetUid.isEmpty) return;

    try {
      final existingQuery = await FirebaseFirestore.instance
          .collection('conversations')
          .where('memberIds', arrayContains: currentUserId)
          .get();

      String conversationId = '';
      for (var doc in existingQuery.docs) {
        final data = doc.data();
        final members = List<String>.from(data['memberIds'] ?? []);
        if (members.contains(targetUid)) {
          conversationId = doc.id;
          break;
        }
      }

      if (conversationId.isEmpty) {
        conversationId = ConversationUtils.generateConversationId(currentUserId, targetUid);
      }

      final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
      final convDoc = await convRef.get();

      if (!convDoc.exists) {
        await convRef.set({
          'conversationId': conversationId,
          'memberIds': [currentUserId, targetUid],
          'status': 'accepted',
          'requestedBy': currentUserId,
          'unreadBy': [],
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: AppTextStyles.bodyLarge(context),
              decoration: InputDecoration(
                hintText: 'Search people, username, phone...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.primary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK SEARCH',
                    style: AppTextStyles.caption(context, color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _buildRecentChip('Alex'),
                      _buildRecentChip('Sarah'),
                      _buildRecentChip('John'),
                    ],
                  ),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoadingWidget(message: 'Searching people...'));
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final uid = data['uid'] ?? '';
                  if (uid == currentUserId) return false;

                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  final username = (data['username'] ?? '').toString().toLowerCase();
                  final phone = (data['phoneNumber'] ?? '').toString().toLowerCase();
                  final q = _query.toLowerCase();

                  return name.contains(q) || username.contains(q) || phone.contains(q);
                }).toList();

                if (filtered.isEmpty) {
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
                            child: const Icon(Icons.person_search_rounded, size: 56, color: Colors.white),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('No matches for "$_query"', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.sm),
                          Text('Check your spelling or search by phone number.', style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
                  itemBuilder: (context, index) {
                    final data = filtered[index].data() as Map<String, dynamic>;
                    final uid = data['uid'] ?? '';
                    final name = data['displayName'] ?? 'User';
                    final about = data['about'] ?? 'Available';
                    final isOnline = data['isOnline'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
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
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.online,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
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
                                  Text(name, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(about, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadows.floating,
                                ),
                                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                              ),
                              onPressed: () => _openChat(uid),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildRecentChip(String label) {
    return ActionChip(
      avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.primary),
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        setState(() => _query = label);
      },
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
    );
  }
}
