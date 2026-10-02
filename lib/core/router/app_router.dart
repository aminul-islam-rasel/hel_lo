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
import '../../features/settings/presentation/storage_screen.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chat/requests',
        builder: (context, state) => const MessageRequestsScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId'] ?? '';
          return ChatDetailScreen(conversationId: conversationId);
        },
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/storage',
        builder: (context, state) => const StorageScreen(),
      ),
      GoRoute(
        path: '/settings/blocked',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/settings/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/status/create',
        builder: (context, state) => const CreateStatusScreen(),
      ),
      GoRoute(
        path: '/status/viewer/:statusId',
        builder: (context, state) {
          final statusId = state.pathParameters['statusId'] ?? '';
          return StatusViewerScreen(statusId: statusId);
        },
      ),
      GoRoute(
        path: '/calls/outgoing',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OutgoingCallScreen(
            receiverId: extra?['receiverId'] ?? '',
            receiverName: extra?['receiverName'] ?? 'User',
            receiverPhoto: extra?['receiverPhoto'],
            callType: extra?['callType'] ?? CallType.audio,
          );
        },
      ),
      GoRoute(
        path: '/calls/incoming',
        builder: (context, state) {
          final call = state.extra as Call;
          return IncomingCallScreen(call: call);
        },
      ),
      GoRoute(
        path: '/calls/audio',
        builder: (context, state) => const AudioCallScreen(),
      ),
      GoRoute(
        path: '/calls/video',
        builder: (context, state) => const VideoCallScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return UserProfileScreen(userId: userId);
        },
      ),
    ],
  );
});
