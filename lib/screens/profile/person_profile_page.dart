import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';
import '../chats/conversation_page.dart';
import '../gifts/gifts_page.dart';

class PersonProfilePage extends StatefulWidget {
  final String personId;

  const PersonProfilePage({super.key, required this.personId});

  @override
  State<PersonProfilePage> createState() => _PersonProfilePageState();
}

class _PersonProfilePageState extends State<PersonProfilePage> {
  late Future<Person> _future;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.getProfile(widget.personId);
  }

  void _reload() => setState(() => _future = WaromApi.instance.getProfile(widget.personId));

  Future<void> _message(Person person) async {
    try {
      final chat = await WaromApi.instance.openChat(person.id);
      final id = '${chat['id'] ?? chat['conversation_id']}';
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationPage(
            conversationId: id,
            title: person.displayName,
            other: person,
          ),
        ),
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Person>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: LoadingBody());
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorBody(error: snap.error!, onRetry: _reload),
          );
        }
        final person = snap.data!;
        final photos = [
          if (person.avatarUrl != null) person.avatarUrl!,
          ...person.photos.where((p) => p.startsWith('http') || p.startsWith('/')),
        ];
        final hobbies = person.hobbies.map((e) => '$e').where((e) => e.isNotEmpty).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.sizeOf(context).height * 0.48,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: MtaaniColors.ink,
                flexibleSpace: FlexibleSpaceBar(
                  background: photos.isEmpty
                      ? Container(
                          color: MtaaniColors.blush,
                          alignment: Alignment.center,
                          child: PersonAvatar(person: person, size: 120),
                        )
                      : PageView(
                          children: [
                            for (final url in photos)
                              Image.network(
                                url.startsWith('http') ? url : url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: MtaaniColors.blush),
                              ),
                          ],
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.displayName,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (person.isVerified)
                            const Icon(Icons.verified_rounded, color: MtaaniColors.coralDeep),
                          if (person.isVip) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.workspace_premium_rounded, color: MtaaniColors.gold),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(person.locationLabel, style: const TextStyle(color: MtaaniColors.muted)),
                      if (person.isOnline) ...[
                        const SizedBox(height: 6),
                        const Text('Online now', style: TextStyle(color: MtaaniColors.like, fontWeight: FontWeight.w700)),
                      ],
                      const SizedBox(height: 20),
                      const Text('About', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        (person.bio == null || person.bio!.trim().isEmpty) ? 'No bio yet.' : person.bio!,
                        style: const TextStyle(fontSize: 15.5, height: 1.45),
                      ),
                      if (hobbies.isNotEmpty) ...[
                        const SizedBox(height: 22),
                        const Text('Interests', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [for (final h in hobbies) InterestChip(label: h)],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GiftsPage(receiverId: person.id, receiverName: person.displayName),
                        ),
                      ),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: const Text('Gift'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MtaaniColors.coralDeep,
                        side: const BorderSide(color: MtaaniColors.line),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _message(person),
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('Message'),
                      style: FilledButton.styleFrom(
                        backgroundColor: MtaaniColors.coralDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
