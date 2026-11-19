import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../calls/calls_page.dart';
import '../chats/chats_page.dart';
import '../discover/discover_page.dart';
import '../income/income_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _tab = 0;
  int _unread = 0;

  static const _pages = [
    HomePage(),
    DiscoverPage(),
    ChatsPage(),
    CallsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
  }

  void openTab(int index) => setState(() => _tab = index);

  Future<void> _refreshUnread() async {
    try {
      final count = await WaromApi.instance.unreadNotifications();
      if (mounted) setState(() => _unread = count);
    } catch (_) {}
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _refreshUnread());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Income',
            onPressed: () => _open(const IncomePage()),
            icon: const Icon(Icons.payments_outlined),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _open(const NotificationsPage()),
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: openTab,
        backgroundColor: Colors.white,
        indicatorColor: MtaaniColors.blush,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: MtaaniColors.coralDeep),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore_rounded, color: MtaaniColors.coralDeep),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: MtaaniColors.coralDeep),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call_rounded, color: MtaaniColors.coralDeep),
            label: 'Calls',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: MtaaniColors.coralDeep),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
