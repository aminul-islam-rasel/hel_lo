import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/text_styles.dart';

class StatusViewerScreen extends ConsumerWidget {
  final String statusId;
  const StatusViewerScreen({super.key, required this.statusId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('statuses').doc(statusId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final userName = data?['userName'] ?? 'Hel Lo User';
        final text = data?['text'] ?? 'Status Story';
        final colorHex = data?['colorHex'] as int?;
        final bgColor = colorHex != null ? Color(colorHex) : AppColors.primary;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Text(
                      text,
                      style: AppTextStyles.displayLarge(context, color: Colors.white).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          1,
                          (index) => Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: AppTextStyles.titleMedium(context, color: Colors.white).copyWith(fontWeight: FontWeight.bold)),
                              Text('Status story', style: AppTextStyles.caption(context, color: Colors.white70)),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
