import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/chat/presentation/message_requests_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/profile_edit_screen.dart';
import '../../features/settings/presentation/privacy_screen.dart';
import '../../features/settings/presentation/notifications_settings_screen.dart';
import '../../features/settings/presentation/blocked_users_screen.dart';
import '../../features/settings/presentation/help_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/status/presentation/create_status_screen.dart';
import '../../features/status/presentation/status_viewer_screen.dart';
import '../../features/calls/presentation/screens/audio_call_screen.dart';
import '../../features/calls/presentation/screens/video_call_screen.dart';
import '../../features/calls/presentation/screens/outgoing_call_screen.dart';
import '../../features/calls/presentation/incoming_call_screen.dart';
import '../../features/calls/domain/entities/call.dart';
import '../../features/profile/presentation/user_profile_screen.dart';

CustomTransitionPage<T> _fadeSlidePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/requests',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const MessageRequestsScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        pageBuilder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return _fadeSlidePage(
            context: context,
            state: state,
            child: ChatDetailScreen(conversationId: conversationId),
          );
        },
      ),
      GoRoute(
        path: '/contacts',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const ContactsScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/profile',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const ProfileEditScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/privacy',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const PrivacyScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const NotificationsSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/blocked',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const BlockedUsersScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/help',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const HelpScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/about',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const AboutScreen(),
        ),
      ),
      GoRoute(
        path: '/status/create',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const CreateStatusScreen(),
        ),
      ),
      GoRoute(
        path: '/status/viewer/:statusId',
        pageBuilder: (context, state) {
          final statusId = state.pathParameters['statusId'] ?? '';
          return _fadeSlidePage(
            context: context,
            state: state,
            child: StatusViewerScreen(statusId: statusId),
          );
        },
      ),
      GoRoute(
        path: '/calls/outgoing',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return _fadeSlidePage(
            context: context,
            state: state,
            child: OutgoingCallScreen(
              receiverId: extra?['receiverId'] ?? '',
              receiverName: extra?['receiverName'] ?? 'User',
              receiverPhoto: extra?['receiverPhoto'],
              callType: extra?['callType'] ?? CallType.audio,
            ),
          );
        },
      ),
      GoRoute(
        path: '/calls/incoming',
        pageBuilder: (context, state) {
          final call = state.extra as Call;
          return _fadeSlidePage(
            context: context,
            state: state,
            child: IncomingCallScreen(call: call),
          );
        },
      ),
      GoRoute(
        path: '/calls/audio',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const AudioCallScreen(),
        ),
      ),
      GoRoute(
        path: '/calls/video',
        pageBuilder: (context, state) => _fadeSlidePage(
          context: context,
          state: state,
          child: const VideoCallScreen(),
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _fadeSlidePage(
            context: context,
            state: state,
            child: UserProfileScreen(userId: userId),
          );
        },
      ),
    ],
  );
});
