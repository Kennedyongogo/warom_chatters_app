import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'warom_api.dart';
import 'warom_auth.dart';
import 'warom_realtime.dart';

enum CallPhase { connecting, ringing, connected, ended }

/// One active 1:1 WebRTC session (voice or video) with Socket.IO signalling.
class WebrtcCallSession {
  WebrtcCallSession({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.isVideo,
    required this.isCaller,
  });

  final String callId;
  final String peerId;
  final String peerName;
  final bool isVideo;
  final bool isCaller;

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _local;
  StreamSubscription? _signals;
  StreamSubscription? _status;
  final _phase = StreamController<CallPhase>.broadcast();
  CallPhase currentPhase = CallPhase.connecting;
  bool _disposed = false;
  bool _remoteDescSet = false;
  bool _accepted = false;
  final _pendingIce = <RTCIceCandidate>[];
  RTCSessionDescription? _queuedOffer;

  Stream<CallPhase> get phases => _phase.stream;

  static const _ice = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  Future<void> start() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    await WaromRealtime.instance.connect();

    _signals = WaromRealtime.instance.callSignals.listen(_onSignal);
    _status = WaromRealtime.instance.callStatus.listen(_onStatus);

    _pc = await createPeerConnection(_ice);
    _pc!.onIceCandidate = (c) {
      if (c.candidate == null) return;
      WaromRealtime.instance.sendCallSignal(
        toUserId: peerId,
        callId: callId,
        signal: {
          'type': 'ice',
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        },
      );
    };
    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        _setPhase(CallPhase.connected);
      }
    };
    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _setPhase(CallPhase.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        if (!_disposed) hangUp(failed: state == RTCPeerConnectionState.RTCPeerConnectionStateFailed);
      }
    };

    if (isCaller) {
      await _attachLocalMedia();
      _setPhase(CallPhase.ringing);
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': isVideo ? 1 : 0,
      });
      await _pc!.setLocalDescription(offer);
      WaromRealtime.instance.sendCallSignal(
        toUserId: peerId,
        callId: callId,
        signal: {'type': 'offer', 'sdp': offer.sdp},
      );
      await WaromApi.instance.updateCall(
        callId,
        status: 'ringing',
        signallingPayload: {'type': 'offer', 'sdp': offer.sdp},
      );
    } else {
      _setPhase(CallPhase.ringing);
    }
  }

  Future<void> acceptIncoming() async {
    _accepted = true;
    await _attachLocalMedia();
    await WaromApi.instance.updateCall(callId, status: 'answered');
    if (_queuedOffer != null) {
      await _acceptOffer(_queuedOffer!);
      _queuedOffer = null;
    }
  }

  Future<void> _attachLocalMedia() async {
    if (_local != null || _pc == null) return;
    _local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo
          ? {
              'facingMode': 'user',
              'width': 640,
              'height': 480,
            }
          : false,
    });
    localRenderer.srcObject = _local;
    for (final track in _local!.getTracks()) {
      await _pc!.addTrack(track, _local!);
    }
  }

  Future<void> reject() async {
    WaromRealtime.instance.sendCallSignal(
      toUserId: peerId,
      callId: callId,
      signal: {'type': 'hangup', 'reason': 'rejected'},
    );
    try {
      await WaromApi.instance.updateCall(callId, status: 'rejected');
    } catch (_) {}
    await releaseMedia();
    _setPhase(CallPhase.ended);
  }

  Future<void> hangUp({bool failed = false}) async {
    if (_disposed) return;
    WaromRealtime.instance.sendCallSignal(
      toUserId: peerId,
      callId: callId,
      signal: {'type': 'hangup'},
    );
    try {
      await WaromApi.instance.updateCall(
        callId,
        status: failed ? 'failed' : 'ended',
      );
    } catch (_) {}
    await releaseMedia();
    _setPhase(CallPhase.ended);
  }

  /// Stops tracks / peer connection but keeps renderers alive until the UI pops.
  Future<void> releaseMedia() async {
    try {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    } catch (_) {}
    for (final t in _local?.getTracks() ?? const <MediaStreamTrack>[]) {
      try {
        await t.stop();
      } catch (_) {}
    }
    try {
      await _local?.dispose();
    } catch (_) {}
    _local = null;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
  }

  Future<void> toggleMute() async {
    final track = _local?.getAudioTracks().firstOrNull;
    if (track == null) return;
    track.enabled = !track.enabled;
  }

  Future<void> toggleCamera() async {
    final track = _local?.getVideoTracks().firstOrNull;
    if (track == null) return;
    track.enabled = !track.enabled;
  }

  Future<void> switchCamera() async {
    final track = _local?.getVideoTracks().firstOrNull;
    if (track == null) return;
    await Helper.switchCamera(track);
  }

  bool get isMicOn => _local?.getAudioTracks().firstOrNull?.enabled ?? false;
  bool get isCamOn => _local?.getVideoTracks().firstOrNull?.enabled ?? false;

  Future<void> _onSignal(Map<String, dynamic> event) async {
    if ('${event['call_id']}' != callId) return;
    if ('${event['from_user_id']}' == WaromAuth.instance.user?['id']?.toString()) return;
    final signal = event['signal'];
    if (signal is! Map) return;
    final type = '${signal['type']}';
    if (type == 'offer') {
      final offer = RTCSessionDescription('${signal['sdp']}', 'offer');
      if (!isCaller) {
        if (!_accepted || _pc == null) {
          _queuedOffer = offer;
        } else {
          await _acceptOffer(offer);
        }
      }
    } else if (type == 'answer') {
      if (isCaller && _pc != null) {
        await _pc!.setRemoteDescription(RTCSessionDescription('${signal['sdp']}', 'answer'));
        _remoteDescSet = true;
        await _flushIce();
        _setPhase(CallPhase.connected);
      }
    } else if (type == 'ice') {
      final candidate = RTCIceCandidate(
        signal['candidate']?.toString(),
        signal['sdpMid']?.toString(),
        signal['sdpMLineIndex'] is int
            ? signal['sdpMLineIndex'] as int
            : int.tryParse('${signal['sdpMLineIndex'] ?? ''}'),
      );
      if (_remoteDescSet && _pc != null) {
        await _pc!.addCandidate(candidate);
      } else {
        _pendingIce.add(candidate);
      }
    } else if (type == 'hangup') {
      await releaseMedia();
      _setPhase(CallPhase.ended);
    }
  }

  Future<void> _onStatus(Map<String, dynamic> event) async {
    final call = event['call'];
    if (call is! Map) return;
    if ('${call['id']}' != callId) return;
    final status = '${call['status']}';
    if (['ended', 'missed', 'rejected', 'failed'].contains(status)) {
      await releaseMedia();
      _setPhase(CallPhase.ended);
    } else if (status == 'answered' && isCaller) {
      _setPhase(CallPhase.connecting);
    }
  }

  Future<void> _acceptOffer(RTCSessionDescription offer) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(offer);
    _remoteDescSet = true;
    await _flushIce();
    final answer = await _pc!.createAnswer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': isVideo ? 1 : 0,
    });
    await _pc!.setLocalDescription(answer);
    WaromRealtime.instance.sendCallSignal(
      toUserId: peerId,
      callId: callId,
      signal: {'type': 'answer', 'sdp': answer.sdp},
    );
    await WaromApi.instance.updateCall(
      callId,
      status: 'answered',
      signallingPayload: {'type': 'answer', 'sdp': answer.sdp},
    );
    _setPhase(CallPhase.connected);
  }

  Future<void> _flushIce() async {
    if (_pc == null) return;
    for (final c in _pendingIce) {
      await _pc!.addCandidate(c);
    }
    _pendingIce.clear();
  }

  void _setPhase(CallPhase phase) {
    currentPhase = phase;
    if (!_phase.isClosed) _phase.add(phase);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _signals?.cancel();
    await _status?.cancel();
    await releaseMedia();
    try {
      await localRenderer.dispose();
    } catch (_) {}
    try {
      await remoteRenderer.dispose();
    } catch (_) {}
    if (!_phase.isClosed) {
      await _phase.close();
    }
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
