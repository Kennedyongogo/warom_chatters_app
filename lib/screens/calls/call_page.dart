import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/webrtc_call_session.dart';
import '../../theme.dart';

class CallPage extends StatefulWidget {
  final WebrtcCallSession session;
  final bool awaitingAccept;

  const CallPage({
    super.key,
    required this.session,
    this.awaitingAccept = false,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late bool _awaiting = widget.awaitingAccept;
  StreamSubscription? _sub;
  bool _micOn = true;
  bool _camOn = true;
  bool _leaving = false;
  DateTime? _connectedAt;
  Timer? _ticker;

  WebrtcCallSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _micOn = session.isMicOn;
    _camOn = session.isCamOn;
    _sub = session.phases.listen((phase) {
      if (!mounted || _leaving) return;
      if (phase == CallPhase.connected) {
        _connectedAt ??= DateTime.now();
        _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
        setState(() => _awaiting = false);
      } else if (phase == CallPhase.ended) {
        _finishAndPop();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _finishAndPop() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _ticker?.cancel();
    // Drop video surfaces before dispose — prevents a stuck black WebRTC overlay.
    setState(() {});
    try {
      await session.releaseMedia();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _endPressed() async {
    if (_leaving) return;
    _leaving = true;
    _ticker?.cancel();
    setState(() {});
    try {
      await session.hangUp();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _declinePressed() async {
    if (_leaving) return;
    _leaving = true;
    setState(() {});
    try {
      await session.reject();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    // Session may already be released; dispose is idempotent.
    session.dispose();
    super.dispose();
  }

  String get _statusText {
    if (_leaving) return 'Call ended';
    if (_awaiting) return 'Incoming ${session.isVideo ? 'video' : 'voice'} call';
    return switch (session.currentPhase) {
      CallPhase.connecting => 'Connecting…',
      CallPhase.ringing => session.isCaller ? 'Ringing…' : 'Connecting…',
      CallPhase.connected => _elapsed,
      CallPhase.ended => 'Call ended',
    };
  }

  String get _elapsed {
    final start = _connectedAt;
    if (start == null) return 'Connected';
    final s = DateTime.now().difference(start).inSeconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  Future<void> _accept() async {
    await session.acceptIncoming();
    if (mounted) setState(() => _awaiting = false);
  }

  @override
  Widget build(BuildContext context) {
    final video = session.isVideo && !_leaving;
    return Scaffold(
      backgroundColor: MtaaniColors.night,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: video
                  ? RTCVideoView(
                      session.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : ColoredBox(
                      color: MtaaniColors.night,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: MtaaniColors.blush,
                              child: Text(
                                session.peerName.isEmpty ? '?' : session.peerName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: MtaaniColors.coralDeep,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              session.peerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_statusText, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ),
            ),
            if (video)
              Positioned(
                right: 16,
                top: 16,
                width: 110,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RTCVideoView(
                    session.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            if (video)
              Positioned(
                left: 20,
                top: 20,
                right: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.peerName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(_statusText, style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            if (!_leaving)
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: _awaiting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RoundBtn(
                            color: const Color(0xFFB42318),
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            onTap: _declinePressed,
                          ),
                          _RoundBtn(
                            color: MtaaniColors.like,
                            icon: Icons.call_rounded,
                            label: 'Accept',
                            onTap: _accept,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RoundBtn(
                            color: Colors.white24,
                            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                            label: _micOn ? 'Mute' : 'Unmute',
                            onTap: () async {
                              await session.toggleMute();
                              setState(() => _micOn = session.isMicOn);
                            },
                          ),
                          _RoundBtn(
                            color: const Color(0xFFB42318),
                            icon: Icons.call_end_rounded,
                            label: 'End',
                            onTap: _endPressed,
                          ),
                          if (session.isVideo)
                            _RoundBtn(
                              color: Colors.white24,
                              icon: _camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                              label: 'Camera',
                              onTap: () async {
                                await session.toggleCamera();
                                setState(() => _camOn = session.isCamOn);
                              },
                            )
                          else
                            _RoundBtn(
                              color: Colors.white24,
                              icon: Icons.volume_up_rounded,
                              label: 'Speaker',
                              onTap: () {},
                            ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundBtn({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
