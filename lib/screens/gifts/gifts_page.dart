import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class GiftsPage extends StatefulWidget {
  final String? receiverId;
  final String? receiverName;

  const GiftsPage({super.key, this.receiverId, this.receiverName});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  late Future<_GiftsBundle> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GiftsBundle> _load() async {
    final catalogue = await WaromApi.instance.catalogue();
    final received = await WaromApi.instance.giftsReceived();
    return _GiftsBundle(catalogue: catalogue, received: received);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _send(String giftId) async {
    final receiverId = widget.receiverId;
    if (receiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a profile first to send a gift')),
      );
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await WaromApi.instance.sendGift(receiverId: receiverId, giftId: giftId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift sent${widget.receiverName == null ? '' : ' to ${widget.receiverName}'}')),
        );
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sending = widget.receiverId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(sending ? 'Send a gift' : 'Gifts'),
      ),
      body: FutureBuilder<_GiftsBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final gifts = (snap.data!.catalogue['gifts'] is List)
              ? snap.data!.catalogue['gifts'] as List
              : const [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              if (sending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SoftCard(
                    child: Text(
                      'Sending to ${widget.receiverName ?? 'this person'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              const SectionLabel('Catalogue'),
              if (gifts.isEmpty)
                const EmptyLike(
                  icon: Icons.card_giftcard_rounded,
                  title: 'No gifts',
                  message: 'Gift catalogue is empty right now.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) {
                    final raw = gifts[i];
                    if (raw is! Map) return const SizedBox.shrink();
                    final g = Map<String, dynamic>.from(raw);
                    return SoftCard(
                      onTap: _sending ? null : () => _send('${g['id']}'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${g['emoji'] ?? '🎁'}', style: const TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text(
                            '${g['name'] ?? 'Gift'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${g['coin_price'] ?? g['price'] ?? 0} coins',
                            style: const TextStyle(color: MtaaniColors.muted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (!sending) ...[
                const SizedBox(height: 18),
                const SectionLabel('Received'),
                if (snap.data!.received.isEmpty)
                  const Text('No gifts received yet.', style: TextStyle(color: MtaaniColors.muted))
                else
                  for (final raw in snap.data!.received)
                    if (raw is Map)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Text('${raw['emoji'] ?? '🎁'}', style: const TextStyle(fontSize: 28)),
                        title: Text(
                          '${raw['gift_name'] ?? raw['name'] ?? 'Gift'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('From ${raw['sender_name'] ?? 'someone'}'),
                      ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GiftsBundle {
  final Map<String, dynamic> catalogue;
  final List<dynamic> received;

  const _GiftsBundle({required this.catalogue, required this.received});
}
