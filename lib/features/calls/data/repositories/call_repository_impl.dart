import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../domain/entities/call.dart';
import '../models/call_model.dart';

class CallRepositoryImpl {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createCall({
    required String callerId,
    required String callerName,
    String? callerPhoto,
    required String receiverId,
    required String receiverName,
    String? receiverPhoto,
    required CallType type,
    required RTCSessionDescription offer,
  }) async {
    final callRef = _firestore.collection('calls').doc();
    final callId = callRef.id;

    final callModel = CallModel(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerPhoto: callerPhoto,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPhoto: receiverPhoto,
      type: type,
      status: CallStatus.ringing,
      participants: [callerId, receiverId],
      createdAt: DateTime.now(),
    );

    await callRef.set(callModel.toMap());

    // Save offer
    await callRef.collection('offer').doc('data').set({
      'type': offer.type,
      'sdp': offer.sdp,
    });

    return callId;
  }

  Future<void> answerCall({
    required String callId,
    required RTCSessionDescription answer,
  }) async {
    final callRef = _firestore.collection('calls').doc(callId);

    await callRef.update({
      'status': CallStatus.accepted.name,
      'answeredAt': FieldValue.serverTimestamp(),
    });

    await callRef.collection('answer').doc('data').set({
      'type': answer.type,
      'sdp': answer.sdp,
    });
  }

  Future<void> updateCallStatus({
    required String callId,
    required CallStatus status,
    int? duration,
    String? endedBy,
  }) async {
    final map = <String, dynamic>{
      'status': status.name,
    };
    if (status == CallStatus.ended || status == CallStatus.rejected || status == CallStatus.cancelled || status == CallStatus.missed) {
      map['endedAt'] = FieldValue.serverTimestamp();
      if (duration != null) map['duration'] = duration;
      if (endedBy != null) map['endedBy'] = endedBy;
    }

    await _firestore.collection('calls').doc(callId).update(map);
  }

  Future<void> addIceCandidate({
    required String callId,
    required RTCIceCandidate candidate,
    required bool isCaller,
  }) async {
    final subcollection = isCaller ? 'callerCandidates' : 'receiverCandidates';
    await _firestore
        .collection('calls')
        .doc(callId)
        .collection(subcollection)
        .add({
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
    });
  }

  Stream<Call?> getCallStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CallModel.fromMap(doc.data()!);
    });
  }

  Stream<List<RTCIceCandidate>> getCandidatesStream(String callId, bool isCaller) {
    final subcollection = isCaller ? 'receiverCandidates' : 'callerCandidates';
    return _firestore
        .collection('calls')
        .doc(callId)
        .collection(subcollection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
      }).toList();
    });
  }

  Future<RTCSessionDescription?> getOffer(String callId) async {
    final doc = await _firestore.collection('calls').doc(callId).collection('offer').doc('data').get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return RTCSessionDescription(data['sdp'], data['type']);
  }

  Future<RTCSessionDescription?> getAnswer(String callId) async {
    final doc = await _firestore.collection('calls').doc(callId).collection('answer').doc('data').get();
    if (!doc.exists || doc.data() == null) return null;
    final data = doc.data()!;
    return RTCSessionDescription(data['sdp'], data['type']);
  }
}
