import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';
import 'providers/call_provider.dart';
import '../domain/entities/call.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final Call call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(callProvider, (previous, next) {
      if (next.currentCall == null || next.currentCall?.status == CallStatus.ended || next.currentCall?.status == CallStatus.rejected) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      } else if (next.currentCall?.status == CallStatus.connected || next.currentCall?.status == CallStatus.accepted) {
        if (widget.call.type == CallType.video) {
          context.go('/calls/video');
        } else {
          context.go('/calls/audio');
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
              Color(0xFF141E30),
              Color(0xFF243B55),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              // Encryption badge
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
                      'Hel Lo Encrypted Call',
                      style: AppTextStyles.caption(context, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Animated Pulsing Avatar
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.all(12 + (_pulseController.value * 20)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.2 - (_pulseController.value * 0.15)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                      child: CircleAvatar(
                        radius: 68,
                        backgroundColor: AppColors.primary,
                        backgroundImage: widget.call.callerPhoto != null ? CachedNetworkImageProvider(widget.call.callerPhoto!) : null,
                        child: widget.call.callerPhoto == null
                            ? Text(
                                widget.call.callerName.isNotEmpty ? widget.call.callerName[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 52, color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                widget.call.type == CallType.video ? 'Incoming Video Call' : 'Incoming Voice Call',
                style: AppTextStyles.titleMedium(context, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.call.callerName,
                style: AppTextStyles.headlineLarge(context, color: Colors.white).copyWith(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const Spacer(),

              // Accept / Decline Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.large(
                          heroTag: 'decline_btn',
                          elevation: 6,
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          onPressed: () {
                            ref.read(callProvider.notifier).rejectCall(widget.call);
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: const Icon(Icons.call_end_rounded, size: 36),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Decline', style: AppTextStyles.titleMedium(context, color: Colors.white70)),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.large(
                          heroTag: 'accept_btn',
                          elevation: 6,
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          onPressed: () {
                            ref.read(callProvider.notifier).answerCall(widget.call);
                          },
                          child: const Icon(Icons.call_rounded, size: 36),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Accept', style: AppTextStyles.titleMedium(context, color: Colors.white)),
                      ],
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
