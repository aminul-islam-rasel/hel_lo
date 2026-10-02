import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/text_styles.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  const ActiveCallScreen({super.key});

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isMuted = false;
  bool _isVideoOn = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _logCall();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
      }
    });
  }

  Future<void> _logCall() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final name = userDoc.data()?['displayName'] ?? 'Hel Lo User';

    await FirebaseFirestore.instance.collection('calls').add({
      'callerId': user.uid,
      'callerName': name,
      'participants': [user.uid],
      'type': 'audio',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxxl),
            Text('Hel Lo Call', style: AppTextStyles.headlineLarge(context, color: Colors.white)),
            const SizedBox(height: AppSpacing.xs),
            Text(_formatDuration(_secondsElapsed), style: AppTextStyles.bodyMedium(context, color: AppColors.secondary)),
            const Spacer(),
            CircleAvatar(
              radius: 80,
              backgroundColor: AppColors.primary,
              child: Icon(_isVideoOn ? Icons.videocam_rounded : Icons.person_rounded, size: 90, color: Colors.white),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallControl(_isMuted ? Icons.mic_off_rounded : Icons.mic_rounded, _isMuted, () {
                    setState(() => _isMuted = !_isMuted);
                  }),
                  _buildCallControl(_isVideoOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, _isVideoOn, () {
                    setState(() => _isVideoOn = !_isVideoOn);
                  }),
                  _buildCallControl(_isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded, _isSpeakerOn, () {
                    setState(() => _isSpeakerOn = !_isSpeakerOn);
                  }),
                  _buildCallControl(Icons.call_end_rounded, true, () => context.pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControl(IconData icon, bool isActiveOrDanger, VoidCallback onPressed) {
    return FloatingActionButton(
      backgroundColor: isActiveOrDanger ? AppColors.error : Colors.white24,
      foregroundColor: Colors.white,
      elevation: 0,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
