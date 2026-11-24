import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class LockedPhotosPage extends StatefulWidget {
  const LockedPhotosPage({super.key});

  @override
  State<LockedPhotosPage> createState() => _LockedPhotosPageState();
}

class _LockedPhotosPageState extends State<LockedPhotosPage> {
  late Future<List<dynamic>> _future;
  final _url = TextEditingController();
  final _price = TextEditingController(text: '50');
  final _caption = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.myLockedPhotos();
  }

  @override
  void dispose() {
    _url.dispose();
    _price.dispose();
    _caption.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = WaromApi.instance.myLockedPhotos());

  Future<void> _create() async {
    final url = _url.text.trim();
    final price = int.tryParse(_price.text.trim()) ?? 0;
    if (url.isEmpty || price <= 0) {
      showWarnSnack(context, 'Need a media URL and coin price');
      return;
    }
    setState(() => _saving = true);
    try {
      await WaromApi.instance.createLockedPhoto(
        mediaUrl: url,
        coinPrice: price,
        caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
      );
      _url.clear();
      _caption.clear();
      if (mounted) {
        showSuccessSnack(context, 'Locked photo added');
        _reload();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locked photos')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingBody();
          if (snap.hasError) return ErrorBody(error: snap.error!, onRetry: _reload);
          final items = snap.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add locked photo', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    TextField(controller: _url, decoration: const InputDecoration(hintText: 'Media URL')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Coin price'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _caption, decoration: const InputDecoration(hintText: 'Caption (optional)')),
                    const SizedBox(height: 12),
                    PillButton.primary(
                      onTap: _saving ? null : _create,
                      height: 48,
                      child: Text(_saving ? 'Saving…' : 'Publish'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Yours'),
              if (items.isEmpty)
                const EmptyLike(
                  icon: Icons.lock_outline_rounded,
                  title: 'No locked photos',
                  message: 'Sell unlockable photos to earn coins.',
                )
              else
                for (final raw in items)
                  if (raw is Map)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: MtaaniColors.coralDeep),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${raw['caption'] ?? 'Locked photo'}',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${raw['coin_price'] ?? 0} coins',
                                    style: const TextStyle(color: MtaaniColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
