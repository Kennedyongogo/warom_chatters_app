import 'package:flutter/material.dart';

import '../../models/person.dart';
import '../../theme.dart';
import '../../widgets/person_widgets.dart';
import 'person_profile_page.dart';

class PeopleListPage extends StatefulWidget {
  final String title;
  final Future<List<Person>> Function() loader;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

  const PeopleListPage({
    super.key,
    required this.title,
    required this.loader,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyIcon = Icons.people_outline_rounded,
  });

  @override
  State<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage> {
  late Future<List<Person>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() => setState(() => _future = widget.loader());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Person>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final people = snap.data ?? const [];
          if (people.isEmpty) {
            return EmptyLike(
              icon: widget.emptyIcon,
              title: widget.emptyTitle,
              message: widget.emptyMessage,
            );
          }
          return RefreshIndicator(
            color: MtaaniColors.coralDeep,
            onRefresh: () async => _reload(),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
