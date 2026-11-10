import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/safety_sheet.dart';
import '../discover/profile_details_page.dart';

class ChatPage extends StatefulWidget {
  final String matchId;

  const ChatPage({super.key, required this.matchId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _api = MtaaniApi.instance;
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _api.addListener(_markReadSoon);
    _markReadSoon();
  }

  @override
  void dispose() {
    _api.removeListener(_markReadSoon);
    _input.dispose();
    super.dispose();
  }

  void _markReadSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _api.me != null) _api.markRead(widget.matchId);
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.sendMessage(widget.matchId, text);
      if (preset == null) _input.clear();
    } catch (e) {
      if (mounted) showApiError(context, e, retry: () => _send(text));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openSafety(Match match) async {
    final other = _api.profile(match.otherThan(_api.me!.id));
    final ended = await showSafetySheet(context, profile: other, matchId: match.isActive ? match.id : null);
    if (ended && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final match = _api.matchById(widget.matchId)!;
    final me = _api.me!;
    final other = _api.profile(match.otherThan(me.id));
    return ListenableBuilder(
      listenable: _api,
      builder: (context, _) {
        final messages = _api.messages(widget.matchId);
        final typing = _api.isTyping(widget.matchId);
        final active = match.isActive;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            titleSpacing: 0,
            title: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileDetailsPage(profile: other)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Avatar(profile: other, size: 40),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(other.firstName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(
                          typing ? 'typing…' : _api.distanceLabel(other),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: typing ? MtaaniColors.coralDeep : MtaaniColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Safety',
                icon: const Icon(Icons.shield_outlined),
                onPressed: () => _openSafety(match),
              ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: MtaaniColors.line),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _EmptyConversation(
                        match: match,
                        name: other.firstName,
                        icebreakers: [
                          'Hey ${other.firstName}! 👋',
                          'What\'s your favourite spot in Nairobi?',
                          if (other.interests.toSet().intersection(me.interests.toSet()).isNotEmpty)
                            'I see you\'re into ${other.interests.toSet().intersection(me.interests.toSet()).first} too!',
                        ],
                        onPick: active ? _send : null,
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        itemCount: messages.length + (typing ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (typing && i == 0) return const _TypingBubble();
                          final index = messages.length - 1 - (i - (typing ? 1 : 0));
                          final m = messages[index];
                          final mine = m.senderId == me.id;
                          final next = index + 1 < messages.length ? messages[index + 1] : null;
                          final showTime = next == null ||
                              next.senderId != m.senderId ||
                              next.sentAt.difference(m.sentAt).inMinutes > 5;
                          return _Bubble(
                            message: m,
                            mine: mine,
                            showTime: showTime,
                            onLongPress: mine ? null : () => reportMessage(context, other, m.text),
                          );
                        },
                      ),
              ),
              if (!active)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.paddingOf(context).bottom),
                  color: MtaaniColors.canvas,
                  child: const Text(
                    'This conversation has ended. New messages can\'t be sent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MtaaniColors.muted, fontWeight: FontWeight.w600),
                  ),
                )
              else
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: MtaaniApi.maxMessageLength,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              counterText: '',
                              fillColor: MtaaniColors.canvas,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: Ink(
                            decoration: const BoxDecoration(gradient: MtaaniColors.brandGradient),
                            child: IconButton(
                              onPressed: _sending ? null : _send,
                              icon: _sending
                                  ? const SizedBox.square(
                                      dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final Match match;
  final String name;
  final List<String> icebreakers;
  final ValueChanged<String>? onPick;

  const _EmptyConversation({required this.match, required this.name, required this.icebreakers, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
      children: [
        const Center(child: HeartMark(size: 54)),
        const SizedBox(height: 14),
        Text(
          'You matched with $name',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('d MMMM, HH:mm').format(match.createdAt),
          textAlign: TextAlign.center,
          style: const TextStyle(color: MtaaniColors.muted),
        ),
        const SizedBox(height: 28),
        if (onPick != null) ...[
          const Text('Break the ice',
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: MtaaniColors.muted)),
          const SizedBox(height: 12),
          for (final line in icebreakers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                onPressed: () => onPick!(line),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MtaaniColors.ink,
                  side: const BorderSide(color: MtaaniColors.line),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(line, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message;
  final bool mine;
  final bool showTime;
  final VoidCallback? onLongPress;

  const _Bubble({required this.message, required this.mine, required this.showTime, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(20);
    return Padding(
      padding: EdgeInsets.only(bottom: showTime ? 10 : 3),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                gradient: mine ? MtaaniColors.brandGradient : null,
                color: mine ? null : const Color(0xFFF4EEEC),
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: mine ? radius : const Radius.circular(6),
                  bottomRight: mine ? const Radius.circular(6) : radius,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(color: mine ? Colors.white : MtaaniColors.ink, fontSize: 15.5, height: 1.35),
              ),
            ),
          ),
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat.Hm().format(message.sentAt),
                      style: const TextStyle(fontSize: 11.5, color: MtaaniColors.muted)),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all_rounded, size: 14, color: MtaaniColors.muted),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF4EEEC), borderRadius: BorderRadius.circular(20)),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MtaaniColors.muted.withValues(
                      alpha: 0.3 + 0.7 * (((_c.value * 3 - i) % 3) < 1 ? 1 - ((_c.value * 3 - i) % 3) : 0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
