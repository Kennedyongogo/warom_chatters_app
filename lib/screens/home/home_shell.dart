import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/warom_api.dart';
import '../../services/warom_realtime.dart';
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

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.travel_explore_outlined, Icons.travel_explore_rounded, 'Discover'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats'),
    (Icons.call_outlined, Icons.call_rounded, 'Calls'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    WaromRealtime.instance.connect();
  }

  @override
  void dispose() {
    // Keep socket alive across tabs; disconnect only on logout elsewhere.
    super.dispose();
  }

  void openTab(int index) {
    if (_tab == index) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = index);
  }

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
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: MtaaniColors.line.withValues(alpha: 0.95))),
          boxShadow: [
            BoxShadow(
              color: MtaaniColors.ink.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _tabs[i].$1,
                      selectedIcon: _tabs[i].$2,
                      label: _tabs[i].$3,
                      selected: _tab == i,
                      onTap: () => openTab(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: MtaaniColors.blush,
        highlightColor: MtaaniColors.blush.withValues(alpha: 0.5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected ? MtaaniColors.blush : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected ? MtaaniColors.coralDeep : MtaaniColors.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? MtaaniColors.coralDeep : MtaaniColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
