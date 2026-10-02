import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/call_provider.dart';
import '../../domain/entities/call.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final CallType callType;

  const OutgoingCallScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
    required this.callType,
  });

  @override
  ConsumerState<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildCenterPreview(CallNotifier callNotifier, CallState callState) {
    if (widget.callType == CallType.video && callNotifier.localRenderer != null && !callState.isCameraOff) {
      return Container(
        width: 220,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.primary, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: RTCVideoView(
            callNotifier.localRenderer!,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(12 + (_pulseController.value * 16)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.15 - (_pulseController.value * 0.1)),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: AppColors.primary,
              backgroundImage: widget.receiverPhoto != null ? CachedNetworkImageProvider(widget.receiverPhoto!) : null,
              child: widget.receiverPhoto == null
                  ? Text(
                      widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);
    final callNotifier = ref.read(callProvider.notifier);

    ref.listen(callProvider, (previous, next) {
      final prevStatus = previous?.currentCall?.status;
      final nextStatus = next.currentCall?.status;

      if (nextStatus == CallStatus.connected || nextStatus == CallStatus.accepted) {
        if (widget.callType == CallType.video) {
          context.go('/calls/video');
        } else {
          context.go('/calls/audio');
        }
      } else if (prevStatus != null &&
          (next.currentCall == null || nextStatus == CallStatus.rejected || nextStatus == CallStatus.cancelled || nextStatus == CallStatus.ended)) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    });

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
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Top Encryption Badge
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

              const Spacer(),

              // Center Video Preview / Animated Avatar
              _buildCenterPreview(callNotifier, callState),

              const SizedBox(height: AppSpacing.xl),

              // Receiver Name
              Text(
                widget.receiverName,
                style: AppTextStyles.headlineLarge(context, color: Colors.white).copyWith(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Call Status Text
              Text(
                widget.callType == CallType.video ? 'Calling video...' : 'Calling audio...',
                style: AppTextStyles.titleMedium(context, color: AppColors.primary),
              ),

              const Spacer(),

              // Quick Controls Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: callState.isMuted ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: () => callNotifier.toggleMute(),
                    ),
                    if (widget.callType == CallType.video)
                      IconButton(
                        icon: Icon(
                          callState.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                          color: callState.isCameraOff ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => callNotifier.toggleCamera(),
                      ),
                    if (widget.callType == CallType.video)
                      IconButton(
                        icon: const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => callNotifier.switchCamera(),
                      ),
                    IconButton(
                      icon: Icon(
                        callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                        color: callState.isSpeakerOn ? AppColors.primary : Colors.white,
                      ),
                      onPressed: () => callNotifier.toggleSpeaker(),
                    ),
                    FloatingActionButton(
                      elevation: 4,
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      onPressed: () {
                        callNotifier.cancelCall();
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
        ),
      ),
    );
  }
}
