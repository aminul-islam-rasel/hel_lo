import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  RTCVideoRenderer? localRenderer;
  RTCVideoRenderer? remoteRenderer;

  Function(MediaStream stream)? onAddRemoteStream;
  Function(RTCPeerConnectionState state)? onConnectionStateChanged;
  Function(RTCIceConnectionState state)? onIceConnectionStateChanged;

  Function(RTCIceCandidate candidate)? _onCandidateCallback;
  final List<RTCIceCandidate> _localIceCandidatesBuffer = [];
  final List<RTCIceCandidate> _queuedRemoteCandidates = [];

  set onCandidate(Function(RTCIceCandidate candidate)? callback) {
    _onCandidateCallback = callback;
    if (callback != null && _localIceCandidatesBuffer.isNotEmpty) {
      debugPrint('Flushing ${_localIceCandidatesBuffer.length} buffered local ICE candidates');
      for (var candidate in List<RTCIceCandidate>.from(_localIceCandidatesBuffer)) {
        callback(candidate);
      }
      _localIceCandidatesBuffer.clear();
    }
  }

  Function(RTCIceCandidate candidate)? get onCandidate => _onCandidateCallback;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      {'urls': 'stun:global.stun.twilio.com:3478'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Map<String, dynamic> _getConstraints({required bool isVideo}) {
    return {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': isVideo,
      },
      'optional': [],
    };
  }

  Future<void> initRenderers() async {
    localRenderer = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();
    await localRenderer?.initialize();
    await remoteRenderer?.initialize();
  }

  Future<void> initAudioSession({required bool isVideo}) async {
    try {
      await Helper.ensureAudioSession();
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await Helper.setAppleAudioConfiguration(
          AppleAudioConfiguration(
            appleAudioCategory: AppleAudioCategory.playAndRecord,
            appleAudioCategoryOptions: {
              AppleAudioCategoryOption.defaultToSpeaker,
              AppleAudioCategoryOption.allowBluetooth,
              AppleAudioCategoryOption.allowAirPlay,
            },
            appleAudioMode: AppleAudioMode.voiceChat,
          ),
        );
      }
      await setSpeakerphoneOn(isVideo);
    } catch (e) {
      debugPrint('Error initializing audio session: $e');
    }
  }

  Future<MediaStream> openUserMedia({required bool isVideo}) async {
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': isVideo
          ? {
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

    final audioTracks = _localStream?.getAudioTracks() ?? [];
    debugPrint('WebRTC openUserMedia: acquired ${audioTracks.length} audio tracks');
    if (audioTracks.isEmpty) {
      debugPrint('WARNING: No audio track found in localStream!');
    } else {
      for (var track in audioTracks) {
        track.enabled = true;
        debugPrint('Local audio track: id=${track.id}, enabled=${track.enabled}, kind=${track.kind}');
      }
    }

    if (isVideo) {
      final videoTracks = _localStream?.getVideoTracks() ?? [];
      debugPrint('WebRTC openUserMedia: acquired ${videoTracks.length} video tracks');
      if (videoTracks.isEmpty) {
        debugPrint('WARNING: No video track found in localStream!');
      } else {
        for (var track in videoTracks) {
          track.enabled = true;
          debugPrint('Local video track: id=${track.id}, enabled=${track.enabled}, kind=${track.kind}');
        }
      }
    }

    if (localRenderer != null && _localStream != null) {
      localRenderer!.srcObject = _localStream;
    }
    return _localStream!;
  }

  Future<void> setupPeerConnection({required bool isVideo}) async {
    final sdpConstraints = _getConstraints(isVideo: isVideo);
    _peerConnection = await createPeerConnection(_iceServers, sdpConstraints);

    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        debugPrint('WebRTC onIceCandidate generated: ${candidate.candidate}');
        if (_onCandidateCallback != null) {
          _onCandidateCallback!(candidate);
        } else {
          debugPrint('Buffering local ICE candidate until callback is set');
          _localIceCandidatesBuffer.add(candidate);
        }
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('WebRTC ICE Connection State: $state');
      if (onIceConnectionStateChanged != null) {
        onIceConnectionStateChanged!(state);
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('WebRTC Peer Connection State: $state');
      if (onConnectionStateChanged != null) {
        onConnectionStateChanged!(state);
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      debugPrint('WebRTC REMOTE TRACK RECEIVED: kind=${event.track.kind}, id=${event.track.id}, enabled=${event.track.enabled}');

      event.track.enabled = true;

      if (event.streams.isNotEmpty) {
        if (_remoteStream == null) {
          _remoteStream = event.streams[0];
        } else {
          if (!_remoteStream!.getTracks().any((t) => t.id == event.track.id)) {
            _remoteStream!.addTrack(event.track);
          }
        }
      } else {
        _remoteStream ??= await createLocalMediaStream('remote_stream');
        if (!_remoteStream!.getTracks().any((t) => t.id == event.track.id)) {
          _remoteStream!.addTrack(event.track);
        }
      }

      for (var track in _remoteStream!.getTracks()) {
        track.enabled = true;
        debugPrint('Remote stream track active: kind=${track.kind}, id=${track.id}, enabled=${track.enabled}');
      }

      if (remoteRenderer != null && _remoteStream != null) {
        remoteRenderer!.srcObject = _remoteStream;
      }

      if (onAddRemoteStream != null && _remoteStream != null) {
        onAddRemoteStream!(_remoteStream!);
      }
    };

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        debugPrint('Adding track to PeerConnection: kind=${track.kind}, id=${track.id}');
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
  }

  Future<RTCSessionDescription> createOffer({required bool isVideo}) async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    final constraints = _getConstraints(isVideo: isVideo);
    RTCSessionDescription description = await _peerConnection!.createOffer(constraints);
    await _peerConnection!.setLocalDescription(description);
    debugPrint('Created SDP Offer: contains audio=${description.sdp?.contains("m=audio")}, contains video=${description.sdp?.contains("m=video")}');
    return description;
  }

  Future<RTCSessionDescription> createAnswer({required bool isVideo}) async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    final constraints = _getConstraints(isVideo: isVideo);
    RTCSessionDescription description = await _peerConnection!.createAnswer(constraints);
    await _peerConnection!.setLocalDescription(description);
    debugPrint('Created SDP Answer: contains audio=${description.sdp?.contains("m=audio")}, contains video=${description.sdp?.contains("m=video")}');
    return description;
  }

  Future<void> setRemoteDescription(String type, String sdp) async {
    if (_peerConnection == null) return;
    RTCSessionDescription description = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(description);
    debugPrint('Remote description set ($type). Processing ${_queuedRemoteCandidates.length} queued remote ICE candidates');

    for (var candidate in List<RTCIceCandidate>.from(_queuedRemoteCandidates)) {
      try {
        await _peerConnection!.addCandidate(candidate);
        debugPrint('Added queued remote ICE candidate successfully');
      } catch (e) {
        debugPrint('Error adding queued remote candidate: $e');
      }
    }
    _queuedRemoteCandidates.clear();
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    final remoteDesc = await _peerConnection!.getRemoteDescription();
    if (remoteDesc == null || remoteDesc.sdp == null || remoteDesc.sdp!.isEmpty) {
      debugPrint('Remote description not set yet. Queuing remote ICE candidate');
      _queuedRemoteCandidates.add(candidate);
      return;
    }

    try {
      await _peerConnection!.addCandidate(candidate);
      debugPrint('Added remote ICE candidate successfully');
    } catch (e) {
      debugPrint('Error adding remote ICE candidate, queuing: $e');
      _queuedRemoteCandidates.add(candidate);
    }
  }

  void toggleMicrophone(bool mute) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !mute;
        debugPrint('Microphone toggled: muted=$mute, track.enabled=${track.enabled}');
      }
    }
  }

  void toggleCamera(bool disable) {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !disable;
        debugPrint('Camera toggled: disabled=$disable, track.enabled=${track.enabled}');
      }
    }
  }

  Future<void> switchCamera() async {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        await Helper.switchCamera(track);
      }
    }
  }

  Future<void> setSpeakerphoneOn(bool enable) async {
    try {
      await Helper.setSpeakerphoneOn(enable);
      debugPrint('Speakerphone set: $enable');
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }
  }

  bool get hasLocalAudio => (_localStream?.getAudioTracks().isNotEmpty ?? false);
  bool get hasLocalVideo => (_localStream?.getVideoTracks().isNotEmpty ?? false);
  bool get hasRemoteAudio => (_remoteStream?.getAudioTracks().isNotEmpty ?? false);
  bool get hasRemoteVideo => (_remoteStream?.getVideoTracks().isNotEmpty ?? false);
  bool get isLocalAudioEnabled => _localStream?.getAudioTracks().firstOrNull?.enabled ?? false;
  bool get isLocalVideoEnabled => _localStream?.getVideoTracks().firstOrNull?.enabled ?? false;

  Future<void> dispose() async {
    try {
      if (_localStream != null) {
        for (var track in _localStream!.getTracks()) {
          track.stop();
        }
        await _localStream!.dispose();
        _localStream = null;
      }
      if (_remoteStream != null) {
        for (var track in _remoteStream!.getTracks()) {
          track.stop();
        }
        await _remoteStream!.dispose();
        _remoteStream = null;
      }
      localRenderer?.srcObject = null;
      remoteRenderer?.srcObject = null;
      await localRenderer?.dispose();
      await remoteRenderer?.dispose();
      await _peerConnection?.close();
      await _peerConnection?.dispose();
      _peerConnection = null;
      _onCandidateCallback = null;
      _localIceCandidatesBuffer.clear();
      _queuedRemoteCandidates.clear();
    } catch (e) {
      debugPrint('Error disposing WebRtcService: $e');
    }
  }
}
