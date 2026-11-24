import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/person.dart';
import '../../services/call_launcher.dart';
import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/person_widgets.dart';
import '../profile/person_profile_page.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<List<Map<String, dynamic>>> _history;
  late Future<List<Map<String, dynamic>>> _missed;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _history = WaromApi.instance.callHistory();
      _missed = WaromApi.instance.missedCalls();
    });
  }

  Person? _peer(Map<String, dynamic> call) {
    final raw = call['other_user'] ?? call['peer'] ?? call['callee'] ?? call['caller'];
    if (raw is Map) return Person.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(
          title: 'Calls',
          subtitle: 'Voice, video, history, and missed',
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        TabBar(
          controller: _tabs,
          labelColor: MtaaniColors.coralDeep,
          unselectedLabelColor: MtaaniColors.muted,
          indicatorColor: MtaaniColors.coralDeep,
          tabs: const [
            Tab(text: 'History'),
            Tab(text: 'Missed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _CallList(future: _history, peerOf: _peer, onRetry: _reload, emptyTitle: 'No calls yet'),
              _CallList(future: _missed, peerOf: _peer, onRetry: _reload, emptyTitle: 'No missed calls'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CallList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final Person? Function(Map<String, dynamic>) peerOf;
  final VoidCallback onRetry;
  final String emptyTitle;

  const _CallList({
    required this.future,
    required this.peerOf,
    required this.onRetry,
    required this.emptyTitle,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingBody();
        if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: onRetry);
        final calls = snap.data ?? const [];
        if (calls.isEmpty) {
          return EmptyLike(
            icon: Icons.call_rounded,
            title: emptyTitle,
            message: 'Incoming and outgoing calls will appear here.',
          );
        }
        return RefreshIndicator(
          color: MtaaniColors.coralDeep,
          onRefresh: () async => onRetry(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: calls.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 88, color: MtaaniColors.line),
            itemBuilder: (context, i) {
              final call = calls[i];
              final peer = peerOf(call);
              final type = '${call['call_type'] ?? call['type'] ?? 'voice'}';
              final status = '${call['status'] ?? ''}';
              final at = DateTime.tryParse('${call['created_at'] ?? call['started_at'] ?? ''}');
              final title = peer?.displayName ?? '${call['peer_name'] ?? 'Unknown'}';
              final isVideo = type.toLowerCase().contains('video');
              final missed = status.toLowerCase().contains('miss');

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: peer == null
                    ? CircleAvatar(
                        backgroundColor: MtaaniColors.blush,
                        child: Icon(
                          isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          color: MtaaniColors.coralDeep,
                        ),
                      )
                    : PersonAvatar(person: peer, size: 52),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: missed ? MtaaniColors.coralDeep : MtaaniColors.ink,
                  ),
                ),
                subtitle: Text(
                  [
                    isVideo ? 'Video' : 'Voice',
                    if (status.isNotEmpty) status,
                    if (at != null) DateFormat.yMMMd().add_jm().format(at.toLocal()),
                  ].join(' · '),
                  style: const TextStyle(color: MtaaniColors.muted, fontSize: 13),
                ),
                trailing: peer == null
                    ? null
                    : IconButton(
                        onPressed: () => CallLauncher.instance.startOutgoingToPerson(
                          context,
                          peer,
                          video: isVideo,
                        ),
                        icon: Icon(
                          isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                          color: MtaaniColors.coralDeep,
                        ),
                      ),
                onTap: peer == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PersonProfilePage(personId: peer.id)),
                        ),
              );
            },
          ),
        );
      },
    );
  }
}
