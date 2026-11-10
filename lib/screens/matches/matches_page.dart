import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';
import 'chat_page.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key});

  void _open(BuildContext context, MatchSummary m) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(matchId: m.match.id)));
  }

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final all = api.matches;
          final fresh = all.where((m) => m.isNew).toList();
          final conversations = all.where((m) => !m.isNew).toList();
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Text('Matches', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink)),
                ),
              ),
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No matches yet',
                    message: 'When you and someone like each other, you\'ll match and can start chatting here.',
                    action: SizedBox(
                      width: 200,
                      child: PillButton.primary(
                        height: 48,
                        onTap: () => context.findAncestorStateOfType<HomeShellState>()?.openTab(0),
                        child: const Text('Start swiping'),
                      ),
                    ),
                  ),
                )
              else ...[
                if (fresh.isNotEmpty) ...[
                  const _SectionTitle('New matches'),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: fresh.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => GestureDetector(
                          onTap: () => _open(context, fresh[i]),
                          child: Column(
                            children: [
                              Avatar(profile: fresh[i].other, size: 70, ring: true),
                              const SizedBox(height: 6),
                              Text(fresh[i].other.firstName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const _SectionTitle('Messages'),
                if (conversations.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text('Say hi to a new match to start a conversation.',
                          style: TextStyle(color: MtaaniColors.muted)),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, i) => _ConversationTile(
                      summary: conversations[i],
                      typing: api.isTyping(conversations[i].match.id),
                      myId: api.me!.id,
                      onTap: () => _open(context, conversations[i]),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(fontSize: 12.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: MtaaniColors.coralDeep)),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final MatchSummary summary;
  final bool typing;
  final String myId;
  final VoidCallback onTap;

  const _ConversationTile({required this.summary, required this.typing, required this.myId, required this.onTap});

  String _time(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0 && now.day == t.day) return DateFormat.Hm().format(t);
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final last = summary.lastMessage!;
    final unread = summary.unread > 0;
    final preview = typing ? 'Typing…' : '${last.senderId == myId ? 'You: ' : ''}${last.text}';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Avatar(profile: summary.other, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(summary.other.firstName,
                      style: TextStyle(fontSize: 16.5, fontWeight: unread ? FontWeight.w800 : FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: typing ? MtaaniColors.coralDeep : (unread ? MtaaniColors.ink : MtaaniColors.muted),
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                      fontStyle: typing ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_time(last.sentAt), style: const TextStyle(fontSize: 12, color: MtaaniColors.muted)),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: MtaaniColors.coralDeep, borderRadius: BorderRadius.circular(100)),
                    child: Text('${summary.unread}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  )
                else
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
