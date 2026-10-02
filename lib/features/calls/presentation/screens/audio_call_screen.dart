import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/call.dart';
import '../providers/call_provider.dart';

class AudioCallScreen extends ConsumerStatefulWidget {
  const AudioCallScreen({super.key});

  @override
  ConsumerState<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends ConsumerState<AudioCallScreen> {
  bool _showDebug = false;

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final callNotifier = ref.read(callProvider.notifier);

    ref.listen(callProvider, (previous, next) {
      if (next.currentCall == null ||
          next.currentCall?.status == CallStatus.ended ||
          next.currentCall?.status == CallStatus.rejected) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    });

    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final call = callState.currentCall;
    final otherName = call?.callerId == currentUserId ? call?.receiverName : call?.callerName;
    final otherPhoto = call?.callerId == currentUserId ? call?.receiverPhoto : call?.callerPhoto;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Header Row with Encrypted Badge and Debug Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'End-to-end encrypted',
                                style: AppTextStyles.caption(context, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.bug_report_rounded,
                            color: _showDebug ? AppColors.primary : Colors.white54,
                            size: 22,
                          ),
                          onPressed: () => setState(() => _showDebug = !_showDebug),
                          tooltip: 'Toggle Debug Info',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Contact Name & Duration
                  Text(
                    otherName ?? 'Hel Lo Call',
                    style: AppTextStyles.headlineLarge(context, color: Colors.white).copyWith(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      callState.callDuration > 0 ? _formatDuration(callState.callDuration) : 'Connecting...',
                      style: AppTextStyles.titleMedium(context, color: AppColors.primary),
                    ),
                  ),

                  const Spacer(),

                  // Center Avatar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: AppColors.primary,
                      backgroundImage: otherPhoto != null ? CachedNetworkImageProvider(otherPhoto) : null,
                      child: otherPhoto == null
                          ? Text(
                              (otherName != null && otherName.isNotEmpty) ? otherName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 56, color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),

                  const Spacer(),

                  // Glass Action Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCallAction(
                          icon: callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: callState.isMuted ? 'Muted' : 'Mute',
                          isActive: callState.isMuted,
                          onPressed: () => callNotifier.toggleMute(),
                        ),
                        _buildCallAction(
                          icon: callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          label: 'Speaker',
                          isActive: callState.isSpeakerOn,
                          onPressed: () => callNotifier.toggleSpeaker(),
                        ),
                        FloatingActionButton(
                          elevation: 4,
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          onPressed: () {
                            callNotifier.endCall();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: const Icon(Icons.call_end_rounded, size: 28),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Debug Section Panel
              if (_showDebug)
                Positioned(
                  top: 60,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('--- WebRTC Debug Info ---', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Call State: ${callState.currentCall?.status.name ?? "None"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('ICE State: ${callState.iceConnectionState?.name ?? "Connecting"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Peer Connection: ${callState.connectionState.name}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Local Audio Track: ${callState.hasLocalAudio ? "YES" : "NO"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Local Video Track: ${callState.hasLocalVideo ? "YES" : "NO"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Remote Audio Track: ${callState.hasRemoteAudio ? "YES" : "NO"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Remote Video Track: ${callState.hasRemoteVideo ? "YES" : "NO"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Microphone Enabled: ${!callState.isMuted ? "ON" : "OFF"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Camera Enabled: ${!callState.isCameraOff ? "ON" : "OFF"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        Text('Speaker Enabled: ${callState.isSpeakerOn ? "ON" : "OFF"}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallAction({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: isActive ? AppColors.primary : Colors.white,
            size: 26,
          ),
          onPressed: onPressed,
        ),
      ],
    );
  }
}
