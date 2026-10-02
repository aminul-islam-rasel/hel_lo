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
      if (next.currentCall == null || next.currentCall?.status == CallStatus.ended || next.currentCall?.status == CallStatus.rejected) {
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
              child: callNotifier.remoteRenderer != null
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

            // Top Status & Duration Bar
            if (_showControls)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    ],
                  ),
                ),
              ),

            // Floating PIP Local Video (Top-Right)
            Positioned(
              top: 60,
              right: 20,
              width: 120,
              height: 170,
              child: GestureDetector(
                onTap: () => callNotifier.switchCamera(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
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
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
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
          ],
        ),
      ),
    );
  }
}
