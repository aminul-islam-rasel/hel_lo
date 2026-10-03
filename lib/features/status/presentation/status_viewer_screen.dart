import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';

class StatusViewerScreen extends ConsumerStatefulWidget {
  final String statusId;
  const StatusViewerScreen({super.key, required this.statusId});

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  double _progress = 0.0;
  bool _isPaused = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {
          _progress = _animController.value;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startStoryTimer(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return;
    if (_animController.isAnimating) return;
    _animController.forward(from: _progress);
    _markAsViewed(docs[_currentIndex]);
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _animController.stop();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    _animController.forward();
  }

  void _nextStory() {
    // Handled in build/state navigation
  }

  Future<void> _markAsViewed(QueryDocumentSnapshot doc) async {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    final data = doc.data() as Map<String, dynamic>;
    final authorId = data['userId'];
    if (authorId == currentUserId) return; // Don't count own view

    final viewedBy = List<String>.from(data['viewedBy'] ?? []);
    if (!viewedBy.contains(currentUserId)) {
      try {
        await doc.reference.update({
          'viewedBy': FieldValue.arrayUnion([currentUserId])
        });
      } catch (e) {
        debugPrint('Error marking status as viewed: $e');
      }
    }
  }

  void _showViewersBottomSheet(BuildContext context, List<dynamic> viewedBy) {
    _pauseStory();
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
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Viewed by (${viewedBy.length})',
                      style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (viewedBy.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: Text('No views yet', style: AppTextStyles.bodyMedium(context, color: Colors.grey)),
                    ),
                  )
                else
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: viewedBy.length,
                      itemBuilder: (context, index) {
                        final viewerId = viewedBy[index] as String;
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('users').doc(viewerId).get(),
                          builder: (context, userSnapshot) {
                            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                            final viewerName = userData?['displayName'] ?? 'User';

                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.person_rounded, color: Colors.white),
                              ),
                              title: Text(viewerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Viewed your story'),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _resumeStory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('statuses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: AppLoadingWidget(message: 'Loading story...')),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text('Story not found', style: AppTextStyles.bodyLarge(context, color: Colors.white)),
            ),
          );
        }

        int initialIndex = docs.indexWhere((doc) => doc.id == widget.statusId);
        if (initialIndex == -1) initialIndex = 0;
        if (_currentIndex == 0 && initialIndex > 0) {
          _currentIndex = initialIndex;
        }
        if (_currentIndex >= docs.length) _currentIndex = docs.length - 1;

        final currentDoc = docs[_currentIndex];
        final data = currentDoc.data() as Map<String, dynamic>;
        final authorId = data['userId'] ?? '';
        final userName = data['userName'] ?? 'Hel Lo User';
        final text = data['text'] ?? 'Status Story';
        final colorHex = data['colorHex'] as int?;
        final bgColor = colorHex != null ? Color(colorHex) : AppColors.primary;
        final viewedBy = List<dynamic>.from(data['viewedBy'] ?? []);
        final isMyStory = authorId == currentUserId;

        if (!_animController.isAnimating && !_isPaused) {
          _startStoryTimer(docs);
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: GestureDetector(
            onTapDown: (_) => _pauseStory(),
            onTapUp: (_) => _resumeStory(),
            onTapCancel: () => _resumeStory(),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        text,
                        style: AppTextStyles.displayLarge(context, color: Colors.white).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Tap zones for left/right navigation
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_currentIndex > 0) {
                              setState(() {
                                _currentIndex--;
                                _progress = 0.0;
                              });
                              _animController.reset();
                              _animController.forward();
                            }
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_currentIndex < docs.length - 1) {
                              setState(() {
                                _currentIndex++;
                                _progress = 0.0;
                              });
                              _animController.reset();
                              _animController.forward();
                            } else {
                              context.pop();
                            }
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),

                  // Top Header & Progress Bars
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    child: Column(
                      children: [
                        // Progress Bars
                        Row(
                          children: List.generate(
                            docs.length,
                            (index) {
                              double segmentProgress = 0.0;
                              if (index < _currentIndex) {
                                segmentProgress = 1.0;
                              } else if (index == _currentIndex) {
                                segmentProgress = _progress;
                              }
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                    child: LinearProgressIndicator(
                                      value: segmentProgress,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 3.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.person_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName, style: AppTextStyles.titleMedium(context, color: Colors.white).copyWith(fontWeight: FontWeight.bold)),
                                Text('Status story', style: AppTextStyles.caption(context, color: Colors.white70)),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => context.pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Viewers Count Bar (if own story)
                  if (isMyStory)
                    Positioned(
                      bottom: AppSpacing.xxl,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _showViewersBottomSheet(context, viewedBy),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${viewedBy.length} views',
                                  style: AppTextStyles.bodyMedium(context, color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
