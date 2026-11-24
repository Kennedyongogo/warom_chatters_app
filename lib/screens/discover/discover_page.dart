import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';
import '../profile/person_profile_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _country = TextEditingController();
  final _city = TextEditingController();
  late Future<List<Person>> _future;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.discover();
  }

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _future = WaromApi.instance.discover(
        country: _country.text.trim(),
        city: _city.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ScreenHeader(
          title: 'Discover',
          subtitle: 'Find people by country and city',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _country,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Country',
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _city,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'City',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _search,
                style: IconButton.styleFrom(
                  backgroundColor: MtaaniColors.coralDeep,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Person>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const LoadingBody();
              }
              if (snap.hasError) {
                return ErrorBody(error: snap.error!, onRetry: _search);
              }
              final people = snap.data ?? const <Person>[];
              if (people.isEmpty) {
                return const EmptyLike(
                  icon: Icons.travel_explore_rounded,
                  title: 'No matches',
                  message: 'Try another country or city, or clear filters to browse everyone.',
                );
              }
              return RefreshIndicator(
                color: MtaaniColors.coralDeep,
                onRefresh: () async => _search(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: people.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 88, color: MtaaniColors.line),
                  itemBuilder: (context, i) {
                    final p = people[i];
                    return PersonTile(
                      person: p,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PersonProfilePage(personId: p.id)),
                      ),
                      trailing: IconButton(
                        tooltip: 'Like',
                        onPressed: () async {
                          try {
                            await WaromApi.instance.swipe(p.id, 'like');
                            if (context.mounted) {
                              showSuccessSnack(context, 'Liked ${p.displayName}');
                            }
                          } catch (e) {
                            if (context.mounted) showApiError(context, e);
                          }
                        },
                        icon: const Icon(Icons.favorite_border_rounded, color: MtaaniColors.coralDeep),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
