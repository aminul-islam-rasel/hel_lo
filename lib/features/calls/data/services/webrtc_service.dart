import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart';

class WebRtcService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  RTCVideoRenderer? localRenderer;
  RTCVideoRenderer? remoteRenderer;

  Function(MediaStream stream)? onAddRemoteStream;
  Function(RTCIceCandidate candidate)? onCandidate;
  Function(RTCPeerConnectionState state)? onConnectionStateChanged;

  final List<RTCIceCandidate> _queuedCandidates = [];

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> initRenderers() async {
    localRenderer = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();
    await localRenderer?.initialize();
    await remoteRenderer?.initialize();
  }

  Future<MediaStream> openUserMedia({required bool isVideo}) async {
    final mediaConstraints = {
      'audio': true,
      'video': isVideo ? {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
        'optional': [],
      } : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (localRenderer != null && _localStream != null) {
      localRenderer!.srcObject = _localStream;
    }
    return _localStream!;
  }

  Future<void> setupPeerConnection({required bool isVideo}) async {
    _peerConnection = await createPeerConnection(_iceServers, _constraints);

    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null && onCandidate != null) {
        onCandidate!(candidate);
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        if (remoteRenderer != null) {
          remoteRenderer!.srcObject = _remoteStream;
        }
        if (onAddRemoteStream != null) {
          onAddRemoteStream!(_remoteStream!);
        }
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('WebRTC Connection State: $state');
      if (onConnectionStateChanged != null) {
        onConnectionStateChanged!(state);
      }
    };

    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track, _localStream!);
      }
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    RTCSessionDescription description = await _peerConnection!.createOffer(_constraints);
    await _peerConnection!.setLocalDescription(description);
    return description;
  }

  Future<RTCSessionDescription> createAnswer() async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    RTCSessionDescription description = await _peerConnection!.createAnswer(_constraints);
    await _peerConnection!.setLocalDescription(description);
    return description;
  }

  Future<void> setRemoteDescription(String type, String sdp) async {
    if (_peerConnection == null) return;
    RTCSessionDescription description = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(description);

    // Apply queued candidates
    for (var candidate in _queuedCandidates) {
      await _peerConnection!.addCandidate(candidate);
    }
    _queuedCandidates.clear();
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    // Check if remote description is set
    try {
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      _queuedCandidates.add(candidate);
    }
  }

  void toggleMicrophone(bool mute) {
    if (_localStream != null) {
      for (var track in _localStream!.getAudioTracks()) {
        track.enabled = !mute;
      }
    }
  }

  void toggleCamera(bool disable) {
    if (_localStream != null) {
      for (var track in _localStream!.getVideoTracks()) {
        track.enabled = !disable;
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
    } catch (e) {
      debugPrint('Error setting speakerphone: $e');
    }
  }

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
      _queuedCandidates.clear();
    } catch (e) {
      debugPrint('Error disposing WebRtcService: $e');
    }
  }
}
