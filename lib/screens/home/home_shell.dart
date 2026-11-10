import 'package:flutter/material.dart';

import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../discover/discover_page.dart';
import '../likes/likes_page.dart';
import '../matches/matches_page.dart';
import '../profile/profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void openTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final api = MtaaniApi.instance;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [DiscoverPage(), LikesPage(), MatchesPage(), ProfilePage()],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: api,
        builder: (context, _) {
          final likes = api.likesReceived.length;
          final unread = api.unreadTotal;
          final newMatches = api.matches.where((m) => m.isNew).length;
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: openTab,
            backgroundColor: Colors.white,
            indicatorColor: MtaaniColors.blush,
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.style_outlined),
                selectedIcon: Icon(Icons.style_rounded, color: MtaaniColors.coralDeep),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Badge(isLabelVisible: likes > 0, label: Text('$likes'), child: const Icon(Icons.favorite_border_rounded)),
                selectedIcon: Badge(
                  isLabelVisible: likes > 0,
                  label: Text('$likes'),
                  child: const Icon(Icons.favorite_rounded, color: MtaaniColors.coralDeep),
                ),
                label: 'Likes',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unread + newMatches > 0,
                  label: Text('${unread + newMatches}'),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unread + newMatches > 0,
                  label: Text('${unread + newMatches}'),
                  child: const Icon(Icons.chat_bubble_rounded, color: MtaaniColors.coralDeep),
                ),
                label: 'Matches',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: MtaaniColors.coralDeep),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
