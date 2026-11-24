import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.notifications();
  }

  void _reload() => setState(() => _future = WaromApi.instance.notifications());

  Future<void> _readAll() async {
    try {
      await WaromApi.instance.readAllNotifications();
      if (mounted) showSuccessSnack(context, 'All notifications marked read');
      _reload();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: _readAll, child: const Text('Mark all read')),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const EmptyLike(
              icon: Icons.notifications_none_rounded,
              title: 'All caught up',
              message: 'Likes, gifts, calls, and admin updates will show here.',
            );
          }
          return RefreshIndicator(
            color: MtaaniColors.coralDeep,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, color: MtaaniColors.line),
              itemBuilder: (context, i) {
                final raw = items[i];
                if (raw is! Map) return const SizedBox.shrink();
                final n = Map<String, dynamic>.from(raw);
                final unread = n['read_at'] == null && n['is_read'] != true;
                final at = DateTime.tryParse('${n['created_at'] ?? ''}');
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: unread ? MtaaniColors.blush : MtaaniColors.line,
                    child: Icon(
                      Icons.notifications_rounded,
                      color: unread ? MtaaniColors.coralDeep : MtaaniColors.muted,
                    ),
                  ),
                  title: Text(
                    '${n['title'] ?? n['type'] ?? 'Update'}',
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: MtaaniColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    [
                      '${n['body'] ?? n['message'] ?? ''}',
                      if (at != null) DateFormat.MMMd().add_jm().format(at.toLocal()),
                    ].where((e) => e.trim().isNotEmpty).join('\n'),
                    style: const TextStyle(color: MtaaniColors.muted, height: 1.35),
                  ),
                  onTap: () async {
                    final id = n['id'];
                    if (id != null && unread) {
                      try {
                        await WaromApi.instance.readNotification('$id');
                        _reload();
                      } catch (_) {}
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
