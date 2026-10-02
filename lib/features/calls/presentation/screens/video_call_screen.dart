import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../domain/entities/call.dart';
import '../providers/call_provider.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  const VideoCallScreen({super.key});

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  bool _showControls = true;
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Remote Fullscreen Video
            Positioned.fill(
              child: callNotifier.remoteRenderer != null &&
                      (callState.hasRemoteStream || callNotifier.remoteRenderer!.srcObject != null)
                  ? RTCVideoView(
                      callNotifier.remoteRenderer!,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: const Color(0xFF0F2027),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: AppSpacing.md),
                            Text('Connecting video stream...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
            ),

            // Top Status & Duration Bar + Debug Toggle
            if (_showControls)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                callState.callDuration > 0 ? _formatDuration(callState.callDuration) : 'Connecting...',
                                style: AppTextStyles.bodyMedium(context, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.bug_report_rounded,
                            color: _showDebug ? AppColors.primary : Colors.white70,
                            size: 22,
                          ),
                          onPressed: () => setState(() => _showDebug = !_showDebug),
                          tooltip: 'Toggle Debug Info',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Debug Panel
            if (_showDebug)
              Positioned(
                top: 80,
                left: 16,
                right: 130,
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

            // Floating PIP Local Video (Top-Right)
            Positioned(
              top: 70,
              right: 16,
              width: 110,
              height: 160,
              child: GestureDetector(
                onTap: () => callNotifier.switchCamera(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: callNotifier.localRenderer != null && !callState.isCameraOff
                        ? RTCVideoView(
                            callNotifier.localRenderer!,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : const Center(
                            child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 36),
                          ),
                  ),
                ),
              ),
            ),

            // Bottom Glassmorphic Action Bar
            if (_showControls)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl, left: AppSpacing.xl, right: AppSpacing.xl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              color: callState.isMuted ? Colors.redAccent : Colors.white,
                              size: 26,
                            ),
                            onPressed: () => callNotifier.toggleMute(),
                          ),
                          IconButton(
                            icon: Icon(
                              callState.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                              color: callState.isCameraOff ? Colors.redAccent : Colors.white,
                              size: 26,
                            ),
                            onPressed: () => callNotifier.toggleCamera(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cameraswitch_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => callNotifier.switchCamera(),
                          ),
                          FloatingActionButton(
                            heroTag: 'video_end_btn',
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
