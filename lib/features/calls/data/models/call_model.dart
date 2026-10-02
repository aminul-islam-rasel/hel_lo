import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/call.dart';

class CallModel extends Call {
  CallModel({
    required super.callId,
    required super.callerId,
    required super.callerName,
    super.callerPhoto,
    required super.receiverId,
    required super.receiverName,
    super.receiverPhoto,
    required super.type,
    required super.status,
    required super.participants,
    required super.createdAt,
    super.answeredAt,
    super.endedAt,
    super.duration,
    super.endedBy,
    super.missed,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPhoto': callerPhoto,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhoto': receiverPhoto,
      'type': type.name,
      'status': status.name,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'answeredAt': answeredAt != null ? Timestamp.fromDate(answeredAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'duration': duration,
      'endedBy': endedBy,
      'missed': missed,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map) {
    return CallModel(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPhoto: map['callerPhoto'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPhoto: map['receiverPhoto'],
      type: CallType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'audio'),
        orElse: () => CallType.audio,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'ringing'),
        orElse: () => CallStatus.ringing,
      ),
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      answeredAt: (map['answeredAt'] as Timestamp?)?.toDate(),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
      duration: map['duration'] ?? 0,
      endedBy: map['endedBy'],
      missed: map['missed'] ?? false,
    );
  }

  factory CallModel.fromEntity(Call call) {
    return CallModel(
      callId: call.callId,
      callerId: call.callerId,
      callerName: call.callerName,
      callerPhoto: call.callerPhoto,
      receiverId: call.receiverId,
      receiverName: call.receiverName,
      receiverPhoto: call.receiverPhoto,
      type: call.type,
      status: call.status,
      participants: call.participants,
      createdAt: call.createdAt,
      answeredAt: call.answeredAt,
      endedAt: call.endedAt,
      duration: call.duration,
      endedBy: call.endedBy,
      missed: call.missed,
    );
  }
}
