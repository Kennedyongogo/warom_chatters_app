import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/person.dart';
import '../../services/warom_api.dart';
import '../../services/warom_auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';
import '../profile/person_profile_page.dart';

class ConversationPage extends StatefulWidget {
  final String conversationId;
  final String title;
  final Person? other;

  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.title,
    this.other,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late Future<List<Map<String, dynamic>>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.messages(widget.conversationId);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = WaromApi.instance.messages(widget.conversationId));

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await WaromApi.instance.sendMessage(widget.conversationId, body: text);
      _input.clear();
      _reload();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = WaromAuth.instance.user?['id']?.toString();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: InkWell(
          onTap: widget.other == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PersonProfilePage(personId: widget.other!.id)),
                  ),
          child: Row(
            children: [
              if (widget.other != null) ...[
                PersonAvatar(person: widget.other!, size: 36),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.other != null)
            IconButton(
              tooltip: 'Voice call',
              onPressed: () async {
                try {
                  await WaromApi.instance.startCall(widget.other!.id, 'voice');
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Voice call started')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  showApiError(this.context, e);
                }
              },
              icon: const Icon(Icons.call_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const LoadingBody();
                }
                if (snap.hasError) {
                  return ErrorBody(error: snap.error!, onRetry: _reload);
                }
                final messages = snap.data ?? const [];
                if (messages.isEmpty) {
                  return const EmptyLike(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Say hello',
                    message: 'Be the first to send a message.',
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final senderId = '${m['sender_id'] ?? m['from_user_id'] ?? ''}';
                    final mine = myId != null && senderId == myId;
                    final body = '${m['body'] ?? m['text'] ?? ''}';
                    final at = DateTime.tryParse('${m['created_at'] ?? m['sent_at'] ?? ''}');
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                        decoration: BoxDecoration(
                          color: mine ? MtaaniColors.coralDeep : MtaaniColors.blush,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(mine ? 18 : 4),
                            bottomRight: Radius.circular(mine ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              body,
                              style: TextStyle(
                                color: mine ? Colors.white : MtaaniColors.ink,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                            if (at != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.jm().format(at.toLocal()),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mine ? Colors.white70 : MtaaniColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: MtaaniColors.coralDeep,
                      foregroundColor: Colors.white,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
