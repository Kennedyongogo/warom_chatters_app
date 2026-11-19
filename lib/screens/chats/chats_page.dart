import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/person.dart';
import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/person_widgets.dart';
import '../home/home_shell.dart';
import 'conversation_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.chats();
  }

  void _reload() => setState(() => _future = WaromApi.instance.chats());

  Person? _other(Map<String, dynamic> chat) {
    final raw = chat['other_user'] ?? chat['other'] ?? chat['participant'];
    if (raw is Map) return Person.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Column(
            children: [
              ScreenHeader(title: 'Chats'),
              Expanded(child: LoadingBody()),
            ],
          );
        }
        if (snap.hasError) {
          return Column(
            children: [
              const ScreenHeader(title: 'Chats'),
              Expanded(child: ErrorBody(error: snap.error!, onRetry: _reload)),
            ],
          );
        }

        final chats = snap.data ?? const [];
        return RefreshIndicator(
          color: MtaaniColors.coralDeep,
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: ScreenHeader(title: 'Chats', subtitle: 'Messages with your matches')),
              if (chats.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyLike(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No chats yet',
                    message: 'Open someone from Home or Discover and start a conversation.',
                  ),
                )
              else
                SliverList.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 88, color: MtaaniColors.line),
                  itemBuilder: (context, i) {
                    final chat = chats[i];
                    final other = _other(chat);
                    final id = '${chat['id']}';
                    final last = chat['last_message'];
                    String preview = 'Say hi';
                    DateTime? at;
                    if (last is Map) {
                      preview = '${last['body'] ?? last['text'] ?? preview}';
                      final rawAt = last['created_at'] ?? last['sent_at'];
                      if (rawAt != null) at = DateTime.tryParse('$rawAt');
                    } else if (chat['last_message_preview'] != null) {
                      preview = '${chat['last_message_preview']}';
                    }
                    final unread = (chat['unread_count'] as num?)?.toInt() ?? 0;
                    final title = other?.displayName ?? '${chat['title'] ?? 'Chat'}';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: other == null
                          ? CircleAvatar(
                              backgroundColor: MtaaniColors.blush,
                              child: Text(title.isEmpty ? '?' : title[0].toUpperCase()),
                            )
                          : PersonAvatar(person: other, size: 52, ring: unread > 0),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: unread > 0 ? MtaaniColors.ink : MtaaniColors.muted,
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (at != null)
                            Text(
                              DateFormat.jm().format(at.toLocal()),
                              style: const TextStyle(fontSize: 12, color: MtaaniColors.muted),
                            ),
                          if (unread > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: MtaaniColors.coralDeep,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConversationPage(
                              conversationId: id,
                              title: title,
                              other: other,
                            ),
                          ),
                        );
                        if (mounted) _reload();
                      },
                    );
                  },
                ),
              if (chats.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: TextButton(
                        onPressed: () => context.findAncestorStateOfType<HomeShellState>()?.openTab(0),
                        child: const Text('Browse Home'),
                      ),
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
