import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  late Future<List<dynamic>> _future;
  final _title = TextEditingController(text: 'My live stream');

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.liveStreams();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = WaromApi.instance.liveStreams());

  Future<void> _start() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    try {
      await WaromApi.instance.startLive(title);
      if (mounted) {
        showSuccessSnack(context, 'Live started');
        _reload();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final streams = snap.data ?? const [];
          return RefreshIndicator(
            color: MtaaniColors.coralDeep,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Go live', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 10),
                      TextField(controller: _title, decoration: const InputDecoration(hintText: 'Stream title')),
                      const SizedBox(height: 12),
                      PillButton.primary(onTap: _start, child: const Text('Start live')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Live now'),
                if (streams.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: EmptyLike(
                      icon: Icons.podcasts_rounded,
                      title: 'Nobody is live',
                      message: 'Start a stream or check back later.',
                    ),
                  )
                else
                  for (final raw in streams)
                    if (raw is Map)
                      SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: MtaaniColors.blush,
                            child: Icon(Icons.podcasts_rounded, color: MtaaniColors.coralDeep),
                          ),
                          title: Text(
                            '${raw['title'] ?? 'Live'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('${raw['host_name'] ?? raw['status'] ?? 'Live'}'),
                          trailing: Text(
                            '${raw['viewer_count'] ?? 0} watching',
                            style: const TextStyle(color: MtaaniColors.muted, fontSize: 12),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
