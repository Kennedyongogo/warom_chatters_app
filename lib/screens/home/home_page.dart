import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/person_widgets.dart';
import '../live/live_page.dart';
import '../profile/person_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, List<Person>>> _future;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.homeFeed();
  }

  void _reload() => setState(() => _future = WaromApi.instance.homeFeed());

  void _open(Person person) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PersonProfilePage(personId: person.id)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Person>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Column(
            children: [
              ScreenHeader(title: 'Home', subtitle: 'People online, offline, and trending'),
              Expanded(child: LoadingBody()),
            ],
          );
        }
        if (snap.hasError) {
          return Column(
            children: [
              const ScreenHeader(title: 'Home'),
              Expanded(child: ErrorBody(error: snap.error!, onRetry: _reload)),
            ],
          );
        }

        final online = snap.data?['online'] ?? const <Person>[];
        final offline = snap.data?['offline'] ?? const <Person>[];
        final trending = snap.data?['trending'] ?? const <Person>[];
        final empty = online.isEmpty && offline.isEmpty && trending.isEmpty;

        return RefreshIndicator(
          color: MtaaniColors.coralDeep,
          onRefresh: () async => _reload(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Home',
                  subtitle: 'People online, offline, and trending',
                  actions: [
                    IconButton(
                      tooltip: 'Live',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LivePage()),
                      ),
                      icon: const Icon(Icons.podcasts_rounded, color: MtaaniColors.ink),
                    ),
                  ],
                ),
              ),
              if (empty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyLike(
                    icon: Icons.home_rounded,
                    title: 'No one here yet',
                    message: 'When people join WAROM, they will show up online, offline, and trending.',
                  ),
                )
              else ...[
                if (online.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionLabel('Online now')),
                  SliverToBoxAdapter(child: _HorizontalPeople(people: online, onTap: _open)),
                ],
                if (trending.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionLabel('Trending')),
                  SliverToBoxAdapter(child: _HorizontalPeople(people: trending, onTap: _open, tall: true)),
                ],
                if (offline.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionLabel('Recently offline')),
                  SliverList.builder(
                    itemCount: offline.length,
                    itemBuilder: (context, i) => PersonTile(
                      person: offline[i],
                      onTap: () => _open(offline[i]),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HorizontalPeople extends StatelessWidget {
  final List<Person> people;
  final void Function(Person) onTap;
  final bool tall;

  const _HorizontalPeople({
    required this.people,
    required this.onTap,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tall ? 168 : 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final p = people[i];
          return GestureDetector(
            onTap: () => onTap(p),
            child: SizedBox(
              width: tall ? 110 : 78,
              child: Column(
                children: [
                  PersonAvatar(person: p, size: tall ? 96 : 70, ring: p.isVip || p.isOnline),
                  const SizedBox(height: 8),
                  Text(
                    p.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  if (tall)
                    Text(
                      p.locationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MtaaniColors.muted, fontSize: 11),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
