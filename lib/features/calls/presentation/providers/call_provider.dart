import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/call.dart';
import '../../data/repositories/call_repository_impl.dart';
import '../../data/services/webrtc_service.dart';
import '../../../../core/utils/conversation_utils.dart';

final callRepositoryProvider = Provider<CallRepositoryImpl>((ref) {
  return CallRepositoryImpl();
});

final webRtcServiceProvider = Provider<WebRtcService>((ref) {
  return WebRtcService();
});

class CallState {
  final Call? currentCall;
  final bool isMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final int callDuration;
  final RTCPeerConnectionState connectionState;
  final RTCIceConnectionState? iceConnectionState;
  final String? errorMessage;
  final bool hasRemoteStream;
  final bool hasLocalAudio;
  final bool hasLocalVideo;
  final bool hasRemoteAudio;
  final bool hasRemoteVideo;

  CallState({
    this.currentCall,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = false,
    this.callDuration = 0,
    this.connectionState = RTCPeerConnectionState.RTCPeerConnectionStateNew,
    this.iceConnectionState,
    this.errorMessage,
    this.hasRemoteStream = false,
    this.hasLocalAudio = false,
    this.hasLocalVideo = false,
    this.hasRemoteAudio = false,
    this.hasRemoteVideo = false,
  });

  CallState copyWith({
    Call? currentCall,
    bool? isMuted,
    bool? isCameraOff,
    bool? isSpeakerOn,
    int? callDuration,
    RTCPeerConnectionState? connectionState,
    RTCIceConnectionState? iceConnectionState,
    String? errorMessage,
    bool? hasRemoteStream,
    bool? hasLocalAudio,
    bool? hasLocalVideo,
    bool? hasRemoteAudio,
    bool? hasRemoteVideo,
  }) {
    return CallState(
      currentCall: currentCall ?? this.currentCall,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      callDuration: callDuration ?? this.callDuration,
      connectionState: connectionState ?? this.connectionState,
      iceConnectionState: iceConnectionState ?? this.iceConnectionState,
      errorMessage: errorMessage,
      hasRemoteStream: hasRemoteStream ?? this.hasRemoteStream,
      hasLocalAudio: hasLocalAudio ?? this.hasLocalAudio,
      hasLocalVideo: hasLocalVideo ?? this.hasLocalVideo,
      hasRemoteAudio: hasRemoteAudio ?? this.hasRemoteAudio,
      hasRemoteVideo: hasRemoteVideo ?? this.hasRemoteVideo,
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  final Ref _ref;
  late final CallRepositoryImpl _callRepository;
  late final WebRtcService _webRtcService;

  Timer? _durationTimer;
  StreamSubscription? _callSubscription;
  StreamSubscription? _candidateSubscription;
  bool _remoteDescriptionSet = false;

  CallNotifier(this._ref) : super(CallState()) {
    _callRepository = _ref.read(callRepositoryProvider);
    _webRtcService = _ref.read(webRtcServiceProvider);
  }

  Future<void> initRenderers() async {
    await _webRtcService.initRenderers();
  }

  RTCVideoRenderer? get localRenderer => _webRtcService.localRenderer;
  RTCVideoRenderer? get remoteRenderer => _webRtcService.remoteRenderer;

  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    String? receiverPhoto,
    required CallType type,
  }) async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isVideo = type == CallType.video;

      final micPermission = await Permission.microphone.request();
      debugPrint('Microphone permission: ${micPermission.isGranted ? "granted" : "denied"}');
      if (!micPermission.isGranted) {
        state = state.copyWith(errorMessage: 'Microphone permission denied');
        return;
      }

      if (isVideo) {
        final cameraPermission = await Permission.camera.request();
        debugPrint('Camera permission: ${cameraPermission.isGranted ? "granted" : "denied"}');
        if (!cameraPermission.isGranted) {
          state = state.copyWith(errorMessage: 'Camera permission denied');
          return;
        }
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final callerName = userDoc.data()?['displayName'] ?? 'Hel Lo User';
      final callerPhoto = userDoc.data()?['profilePhoto'];

      await initRenderers();
      await _webRtcService.initAudioSession(isVideo: isVideo);
      await _webRtcService.openUserMedia(isVideo: isVideo);
      await _webRtcService.setupPeerConnection(isVideo: isVideo);

      final offer = await _webRtcService.createOffer(isVideo: isVideo);

      final callId = await _callRepository.createCall(
        callerId: user.uid,
        callerName: callerName,
        callerPhoto: callerPhoto,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPhoto: receiverPhoto,
        type: type,
        offer: offer,
      );

      final newCall = Call(
        callId: callId,
        callerId: user.uid,
        callerName: callerName,
        callerPhoto: callerPhoto,
        receiverId: receiverId,
        receiverName: receiverName,
        receiverPhoto: receiverPhoto,
        type: type,
        status: CallStatus.ringing,
        participants: [user.uid, receiverId],
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        currentCall: newCall,
        isSpeakerOn: isVideo,
        hasLocalAudio: _webRtcService.hasLocalAudio,
        hasLocalVideo: _webRtcService.hasLocalVideo,
      );

      _setupWebRtcCallbacks(callId: callId, isCaller: true);
      _listenToCall(callId, isCaller: true);
    } catch (e) {
      debugPrint('Error starting call: $e');
      state = state.copyWith(errorMessage: 'Could not start call: $e');
    }
  }

  Future<void> answerCall(Call call) async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isVideo = call.type == CallType.video;

      final micPermission = await Permission.microphone.request();
      debugPrint('Microphone permission: ${micPermission.isGranted ? "granted" : "denied"}');
      if (!micPermission.isGranted) {
        state = state.copyWith(errorMessage: 'Microphone permission denied');
        return;
      }

      if (isVideo) {
        final cameraPermission = await Permission.camera.request();
        debugPrint('Camera permission: ${cameraPermission.isGranted ? "granted" : "denied"}');
        if (!cameraPermission.isGranted) {
          state = state.copyWith(errorMessage: 'Camera permission denied');
          return;
        }
      }

      await initRenderers();
      await _webRtcService.initAudioSession(isVideo: isVideo);
      await _webRtcService.openUserMedia(isVideo: isVideo);
      await _webRtcService.setupPeerConnection(isVideo: isVideo);

      _setupWebRtcCallbacks(callId: call.callId, isCaller: false);

      final offer = await _callRepository.getOffer(call.callId);
      if (offer != null) {
        await _webRtcService.setRemoteDescription(offer.type ?? 'offer', offer.sdp ?? '');
      }

      final answer = await _webRtcService.createAnswer(isVideo: isVideo);
      await _callRepository.answerCall(callId: call.callId, answer: answer);

      state = state.copyWith(
        currentCall: call.copyWith(status: CallStatus.accepted, answeredAt: DateTime.now()),
        isSpeakerOn: isVideo,
        hasLocalAudio: _webRtcService.hasLocalAudio,
        hasLocalVideo: _webRtcService.hasLocalVideo,
      );

      _listenToCall(call.callId, isCaller: false);
    } catch (e) {
      debugPrint('Error answering call: $e');
      state = state.copyWith(errorMessage: 'Could not answer call: $e');
    }
  }

  Future<void> rejectCall(Call call) async {
    try {
      await _callRepository.updateCallStatus(
        callId: call.callId,
        status: CallStatus.rejected,
        endedBy: fb.FirebaseAuth.instance.currentUser?.uid,
      );
      await _logCallMessage(call, CallStatus.rejected);
      await _cleanup();
    } catch (e) {
      debugPrint('Error rejecting call: $e');
    }
  }

  Future<void> cancelCall() async {
    if (state.currentCall == null) return;
    try {
      await _callRepository.updateCallStatus(
        callId: state.currentCall!.callId,
        status: CallStatus.cancelled,
        endedBy: fb.FirebaseAuth.instance.currentUser?.uid,
      );
      await _logCallMessage(state.currentCall!, CallStatus.cancelled);
      await _cleanup();
    } catch (e) {
      debugPrint('Error cancelling call: $e');
    }
  }

  Future<void> endCall() async {
    if (state.currentCall == null) return;
    try {
      await _callRepository.updateCallStatus(
        callId: state.currentCall!.callId,
        status: CallStatus.ended,
        duration: state.callDuration,
        endedBy: fb.FirebaseAuth.instance.currentUser?.uid,
      );
      await _logCallMessage(state.currentCall!, CallStatus.ended);
      await _cleanup();
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  Future<void> _logCallMessage(Call call, CallStatus status) async {
    try {
      final conversationId = ConversationUtils.generateConversationId(call.callerId, call.receiverId);
      final convRef = FirebaseFirestore.instance.collection('conversations').doc(conversationId);

      final mins = (state.callDuration ~/ 60).toString().padLeft(2, '0');
      final secs = (state.callDuration % 60).toString().padLeft(2, '0');
      final durationStr = state.callDuration > 0 ? ' • $mins:$secs' : '';

      String text;
      if (status == CallStatus.missed) {
        text = call.type == CallType.video ? '📞 Missed video call' : '📞 Missed audio call';
      } else if (status == CallStatus.rejected) {
        text = call.type == CallType.video ? '📹 Rejected video call' : '📞 Rejected audio call';
      } else if (status == CallStatus.cancelled) {
        text = call.type == CallType.video ? '📹 Cancelled video call' : '📞 Cancelled audio call';
      } else {
        text = call.type == CallType.video ? '📹 Video call$durationStr' : '📞 Audio call$durationStr';
      }

      final messageRef = convRef.collection('messages').doc();
      await messageRef.set({
        'messageId': messageRef.id,
        'senderId': call.callerId,
        'type': 'call',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isEdited': false,
        'readBy': [call.callerId],
        'deliveredTo': [call.callerId],
      });

      await convRef.set({
        'conversationId': conversationId,
        'memberIds': [call.callerId, call.receiverId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': call.callerId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error logging call message: $e');
    }
  }

  void toggleMute() {
    final newMute = !state.isMuted;
    _webRtcService.toggleMicrophone(newMute);
    state = state.copyWith(isMuted: newMute);
  }

  void toggleCamera() {
    final newCameraOff = !state.isCameraOff;
    _webRtcService.toggleCamera(newCameraOff);
    state = state.copyWith(isCameraOff: newCameraOff);
  }

  Future<void> switchCamera() async {
    await _webRtcService.switchCamera();
  }

  void toggleSpeaker() {
    final newSpeaker = !state.isSpeakerOn;
    _webRtcService.setSpeakerphoneOn(newSpeaker);
    state = state.copyWith(isSpeakerOn: newSpeaker);
  }

  void _setupWebRtcCallbacks({required String callId, required bool isCaller}) {
    _webRtcService.onCandidate = (RTCIceCandidate candidate) {
      final targetCallId = callId.isNotEmpty ? callId : (state.currentCall?.callId ?? '');
      if (targetCallId.isNotEmpty) {
        debugPrint('Saving ICE candidate to Firestore for callId=$targetCallId, isCaller=$isCaller');
        _callRepository.addIceCandidate(
          callId: targetCallId,
          candidate: candidate,
          isCaller: isCaller,
        );
      } else {
        debugPrint('WARNING: Cannot save ICE candidate because callId is empty!');
      }
    };

    _webRtcService.onAddRemoteStream = (MediaStream stream) {
      debugPrint('Remote stream callback triggered in CallNotifier');
      state = state.copyWith(
        hasRemoteStream: true,
        hasRemoteAudio: _webRtcService.hasRemoteAudio,
        hasRemoteVideo: _webRtcService.hasRemoteVideo,
      );
    };

    _webRtcService.onConnectionStateChanged = (RTCPeerConnectionState connectionState) {
      debugPrint('CallNotifier RTCPeerConnectionState: $connectionState');
      state = state.copyWith(connectionState: connectionState);
      if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startDurationTimer();
      }
    };

    _webRtcService.onIceConnectionStateChanged = (RTCIceConnectionState iceState) {
      debugPrint('CallNotifier RTCIceConnectionState: $iceState');
      state = state.copyWith(iceConnectionState: iceState);
      if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _startDurationTimer();
      }
    };

    final effectiveCallId = callId.isNotEmpty ? callId : (state.currentCall?.callId ?? '');
    if (effectiveCallId.isNotEmpty) {
      final Set<String> processedCandidates = {};
      _candidateSubscription?.cancel();
      _candidateSubscription = _callRepository
          .getCandidatesStream(effectiveCallId, isCaller)
          .listen((candidates) {
        for (var candidate in candidates) {
          final key = '${candidate.candidate}_${candidate.sdpMid}_${candidate.sdpMLineIndex}';
          if (!processedCandidates.contains(key)) {
            processedCandidates.add(key);
            debugPrint('Applying candidate from Firestore: $key');
            _webRtcService.addCandidate(candidate);
          }
        }
      });
    }
  }

  void _listenToCall(String callId, {required bool isCaller}) {
    _callSubscription = _callRepository.getCallStream(callId).listen((call) async {
      if (call == null) return;

      state = state.copyWith(currentCall: call);

      if (isCaller && call.status == CallStatus.accepted && !_remoteDescriptionSet) {
        final answer = await _callRepository.getAnswer(callId);
        if (answer != null) {
          _remoteDescriptionSet = true;
          await _webRtcService.setRemoteDescription(answer.type ?? 'answer', answer.sdp ?? '');
          await _callRepository.updateCallStatus(callId: callId, status: CallStatus.connected);
          _startDurationTimer();
        }
      } else if (!isCaller && call.status == CallStatus.accepted) {
        _startDurationTimer();
      } else if (call.status == CallStatus.connected) {
        _startDurationTimer();
      }

      if (call.status == CallStatus.ended ||
          call.status == CallStatus.rejected ||
          call.status == CallStatus.cancelled ||
          call.status == CallStatus.missed) {
        await _cleanup();
      }
    });
  }

  void _startDurationTimer() {
    if (_durationTimer != null && _durationTimer!.isActive) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(callDuration: state.callDuration + 1);
    });
  }

  Future<void> _cleanup() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _callSubscription?.cancel();
    _callSubscription = null;
    _candidateSubscription?.cancel();
    _candidateSubscription = null;
    _remoteDescriptionSet = false;

    await _webRtcService.dispose();
    state = CallState();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(ref);
});
