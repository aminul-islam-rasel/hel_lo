import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/conversation_utils.dart';
import '../../../core/widgets/app_loading_widget.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _isLoadingContacts = true;
  Set<String> _devicePhoneNumbers = {};
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceContacts();
  }

  Future<void> _loadDeviceContacts() async {
    try {
      setState(() => _isLoadingContacts = true);
      
      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        status = await Permission.contacts.request();
      }

      if (status.isGranted || await FlutterContacts.requestPermission()) {
        setState(() => _permissionGranted = true);
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        final Set<String> numbers = {};
        for (var contact in contacts) {
          for (var phone in contact.phones) {
            final normalized = _normalizePhoneNumber(phone.number);
            if (normalized.isNotEmpty) {
              numbers.add(normalized);
            }
          }
        }
        setState(() {
          _devicePhoneNumbers = numbers;
          _permissionGranted = true;
          _isLoadingContacts = false;
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _permissionGranted = false;
          _isLoadingContacts = false;
        });
        await openAppSettings();
      } else {
        setState(() {
          _permissionGranted = false;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingContacts = false);
      debugPrint('Error loading device contacts: $e');
    }
  }

  String _normalizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    }
    return digits;
  }

  Future<void> _openChat(BuildContext context, String targetUid) async {
    try {
      final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null || targetUid.isEmpty) return;

      final conversationId = ConversationUtils.generateConversationId(currentUserId, targetUid);
      final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);
      final convDoc = await convRef.get();

      if (!convDoc.exists) {
        await convRef.set({
          'conversationId': conversationId,
          'memberIds': [currentUserId, targetUid],
          'status': 'pending',
          'requestedBy': currentUserId,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        context.push('/chat/$conversationId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = fb.FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Find People', style: AppTextStyles.headlineLarge(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Contacts on Hel Lo', style: AppTextStyles.caption(context, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: _isLoadingContacts
          ? const Center(child: AppLoadingWidget(message: 'Syncing device contacts...'))
          : !_permissionGranted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.contacts_rounded, size: 56, color: AppColors.primary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Contacts Permission Needed', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Allow access to your contacts to discover who is on Hel Lo.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            boxShadow: AppShadows.floating,
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            onPressed: _loadDeviceContacts,
                            child: const Text('Grant Access'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: AppLoadingWidget(message: 'Finding registered contacts...'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text('No users found.', style: AppTextStyles.bodyMedium(context)),
                      );
                    }

                    final users = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = data['uid'] ?? doc.id;
                      if (uid == currentUserId) return false;

                      final userPhone = data['phoneNumber'] ?? '';
                      final normalizedUserPhone = _normalizePhoneNumber(userPhone);

                      return _devicePhoneNumbers.contains(normalizedUserPhone);
                    }).toList();

                    if (users.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadows.floating,
                                ),
                                child: const Icon(Icons.person_search_rounded, size: 56, color: Colors.white),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text('No Contacts Found', style: AppTextStyles.headlineMedium(context).copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: AppSpacing.xs),
                              Text('None of your phone contacts are registered on Hel Lo yet.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(context, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final user = userDoc.data() as Map<String, dynamic>;
                        final uid = user['uid'] ?? userDoc.id;
                        final name = user['displayName'] ?? 'User';
                        final about = user['about'] ?? 'Available';
                        final isOnline = user['isOnline'] ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightCard,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        gradient: isOnline ? AppGradients.statusRing : null,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const CircleAvatar(
                                        radius: 26,
                                        backgroundColor: AppColors.primary,
                                        child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                                      ),
                                    ),
                                    if (isOnline)
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppColors.online,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: AppTextStyles.titleMedium(context).copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(about, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodySmall(context, color: theme.colorScheme.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.floating,
                                    ),
                                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                                  ),
                                  onPressed: () => _openChat(context, uid),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
