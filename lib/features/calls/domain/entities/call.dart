import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { audio, video }
enum CallStatus { ringing, accepted, rejected, cancelled, connected, ended, missed, failed }

class Call {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerPhoto;
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final CallType type;
  final CallStatus status;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int duration;
  final String? endedBy;
  final bool missed;

  Call({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerPhoto,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
    required this.type,
    required this.status,
    required this.participants,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.duration = 0,
    this.endedBy,
    this.missed = false,
  });

  Call copyWith({
    String? callId,
    String? callerId,
    String? callerName,
    String? callerPhoto,
    String? receiverId,
    String? receiverName,
    String? receiverPhoto,
    CallType? type,
    CallStatus? status,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? duration,
    String? endedBy,
    bool? missed,
  }) {
    return Call(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      callerName: callerName ?? this.callerName,
      callerPhoto: callerPhoto ?? this.callerPhoto,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverPhoto: receiverPhoto ?? this.receiverPhoto,
      type: type ?? this.type,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      duration: duration ?? this.duration,
      endedBy: endedBy ?? this.endedBy,
      missed: missed ?? this.missed,
    );
  }
}
