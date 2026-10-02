import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/services/notification_service.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../status/presentation/status_screen.dart';
import '../../calls/presentation/calls_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../calls/data/models/call_model.dart';
import '../../calls/domain/entities/call.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _incomingMessageSubscription;

  final List<Widget> _screens = const [
    ChatListScreen(),
    StatusScreen(),
    CallsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToIncomingCalls();
    _listenToIncomingMessages();
  }

  void _listenToIncomingCalls() {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _incomingCallSubscription = FirebaseFirestore.instance
        .collection('calls')
        .where('receiverId', isEqualTo: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
            final data = change.doc.data();
            if (data != null) {
              final call = CallModel.fromMap(data);
              if (call.status == CallStatus.ringing) {
                if (mounted) {
                  context.push('/calls/incoming', extra: call);
                }
              }
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Incoming call listener error: $error');
      },
    );
  }

  void _listenToIncomingMessages() {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _incomingMessageSubscription = FirebaseFirestore.instance
        .collection('conversations')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final lastSenderId = data['lastMessageSenderId'];
              final lastMessage = data['lastMessage'] ?? 'New message';

              if (lastSenderId != null && lastSenderId != currentUserId) {
                final lastTime = (data['lastMessageTime'] as Timestamp?)?.toDate();
                if (lastTime != null && DateTime.now().difference(lastTime).inSeconds < 10) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(lastSenderId)
                      .get()
                      .then((doc) {
                    final senderName = doc.data()?['displayName'] ?? 'Hel Lo Message';
                    NotificationService.showLocalNotification(
                      title: senderName,
                      body: lastMessage,
                    );
                  }).catchError((e) {
                    debugPrint('Error fetching sender profile for notification: $e');
                  });
                }
              }
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Incoming message listener error: $error');
      },
    );
  }

  @override
  void dispose() {
    _incomingCallSubscription?.cancel();
    _incomingMessageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withOpacity(0.92)
                  : Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.primary.withOpacity(0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, 'Chats', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
                _buildNavItem(1, 'Stories', Icons.auto_awesome_outlined, Icons.auto_awesome_rounded),
                _buildNavItem(2, 'Calls', Icons.phone_outlined, Icons.phone_rounded),
                _buildNavItem(3, 'Settings', Icons.person_outline_rounded, Icons.person_rounded),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? Padding(
              padding: const EdgeInsets.only(bottom: 76.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.floating,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    onTap: () {
                      if (_currentIndex == 0) {
                        context.push('/contacts');
                      } else {
                        context.push('/status/create');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        _currentIndex == 0 ? Icons.add_comment_rounded : Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, IconData selectedIcon) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs + 2),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
