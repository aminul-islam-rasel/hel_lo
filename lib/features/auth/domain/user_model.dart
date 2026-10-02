import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phoneNumber;
  final String displayName;
  final String username;
  final String? profilePhoto;
  final String about;
  final String status;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final bool isVerified;
  final String? pushToken;
  final Map<String, dynamic> privacySettings;
  final Map<String, dynamic> notificationSettings;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.displayName,
    required this.username,
    this.profilePhoto,
    required this.about,
    required this.status,
    required this.createdAt,
    required this.lastSeen,
    required this.isOnline,
    required this.isVerified,
    this.pushToken,
    required this.privacySettings,
    required this.notificationSettings,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'username': username,
      'profilePhoto': profilePhoto,
      'about': about,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'isVerified': isVerified,
      'pushToken': pushToken,
      'privacySettings': privacySettings,
      'notificationSettings': notificationSettings,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'] ?? '',
      username: map['username'] ?? '',
      profilePhoto: map['profilePhoto'],
      about: map['about'] ?? 'Hey there! I am using WhatsApp.',
      status: map['status'] ?? 'Available',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: map['isOnline'] ?? false,
      isVerified: map['isVerified'] ?? false,
      pushToken: map['pushToken'],
      privacySettings: map['privacySettings'] ?? {
        'profilePhoto': 'everyone',
        'lastSeen': 'everyone',
        'about': 'everyone',
        'readReceipts': true,
      },
      notificationSettings: map['notificationSettings'] ?? {
        'sound': true,
        'vibrate': true,
        'preview': true,
      },
    );
  }
}
