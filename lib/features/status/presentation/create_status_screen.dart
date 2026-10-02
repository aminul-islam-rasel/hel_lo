import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_loading_widget.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  final _statusController = TextEditingController();
  Color _backgroundColor = AppColors.primary;
  bool _isPosting = false;

  final List<Color> _colors = [
    AppColors.primary,
    const Color(0xFF4338CA),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
    const Color(0xFF0F172A),
  ];

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _postStatus() async {
    final text = _statusController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);

    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['displayName'] ?? 'Hel Lo User';

      final docRef = FirebaseFirestore.instance.collection('statuses').doc();
      await docRef.set({
        'statusId': docRef.id,
        'userId': user.uid,
        'userName': userName,
        'text': text,
        'colorHex': _backgroundColor.value,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story posted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post story: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                final currentIndex = _colors.indexOf(_backgroundColor);
                _backgroundColor = _colors[(currentIndex + 1) % _colors.length];
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: TextField(
            controller: _statusController,
            autofocus: true,
            maxLines: 5,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge(context, color: Colors.white).copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: 'Share a thought...',
              hintStyle: TextStyle(color: Colors.white60),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.floating,
                ),
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  foregroundColor: _backgroundColor,
                  elevation: 0,
                  onPressed: _isPosting ? null : _postStatus,
                  child: _isPosting
                      ? AppLoadingWidget.small(color: _backgroundColor)
                      : const Icon(Icons.send_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
