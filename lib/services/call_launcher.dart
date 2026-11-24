import 'package:flutter/material.dart';

import '../models/person.dart';
import '../screens/calls/call_page.dart';
import '../widgets/common.dart';
import 'warom_api.dart';
import 'warom_auth.dart';
import 'warom_realtime.dart';
import 'webrtc_call_session.dart';

/// Starts outgoing calls and presents incoming WebRTC call screens.
class CallLauncher {
  CallLauncher._();
  static final instance = CallLauncher._();

  GlobalKey<NavigatorState>? navigatorKey;
  bool _listening = false;
  bool _busy = false;

  void attach(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    _listenIncoming();
  }

  void _listenIncoming() {
    if (_listening) return;
    _listening = true;
    WaromRealtime.instance.incomingCalls.listen((event) async {
      if (_busy) return;
      final nav = navigatorKey?.currentState;
      if (nav == null) return;

      final call = event['call'];
      if (call is! Map) return;
      final callMap = Map<String, dynamic>.from(call);
      final callId = '${callMap['id']}';
      final callerId = '${event['caller_id'] ?? callMap['caller_id']}';
      final me = WaromAuth.instance.user?['id']?.toString();
      if (me != null && callerId == me) return;

      final isVideo = '${callMap['call_type']}' == 'video';
      String peerName = 'Incoming call';
      try {
        final person = await WaromApi.instance.getProfile(callerId);
        peerName = person.displayName;
      } catch (_) {}

      final session = WebrtcCallSession(
        callId: callId,
        peerId: callerId,
        peerName: peerName,
        isVideo: isVideo,
        isCaller: false,
      );

      _busy = true;
      try {
        await session.start();
        await nav.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => CallPage(session: session, awaitingAccept: true),
          ),
        );
      } catch (e) {
        await session.dispose();
        final ctx = navigatorKey?.currentContext;
        if (ctx != null && ctx.mounted) showApiError(ctx, e);
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> startOutgoing(
    BuildContext context, {
    required String peerId,
    required String peerName,
    required bool video,
  }) async {
    if (_busy) return;
    _busy = true;
    WebrtcCallSession? session;
    try {
      await WaromRealtime.instance.connect();
      final call = await WaromApi.instance.startCall(peerId, video ? 'video' : 'voice');
      final callId = '${call['id']}';
      session = WebrtcCallSession(
        callId: callId,
        peerId: peerId,
        peerName: peerName,
        isVideo: video,
        isCaller: true,
      );
      await session.start();
      if (!context.mounted) {
        await session.dispose();
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => CallPage(session: session!, awaitingAccept: false),
        ),
      );
    } catch (e) {
      await session?.dispose();
      if (context.mounted) showApiError(context, e);
    } finally {
      _busy = false;
    }
  }

  Future<void> startOutgoingToPerson(BuildContext context, Person person, {required bool video}) {
    return startOutgoing(
      context,
      peerId: person.id,
      peerName: person.displayName,
      video: video,
    );
  }
}
