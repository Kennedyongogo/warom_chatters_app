import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/person_widgets.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  late Future<List<dynamic>> _future;
  String _kind = 'chatter_kyc';
  final _url = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = WaromApi.instance.verifications();
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _future = WaromApi.instance.verifications());

  Future<void> _submit() async {
    final url = _url.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste a document URL (upload via media API first)')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await WaromApi.instance.submitVerification(kind: _kind, documentUrls: [url]);
      _url.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted for review')));
        _reload();
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC & verification')),
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
                    const Text(
                      'Verify to withdraw earnings',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Submit age, identity, or chatter KYC documents. Admins review before payouts.',
                      style: TextStyle(color: MtaaniColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: const InputDecoration(labelText: 'Verification type'),
                      items: const [
                        DropdownMenuItem(value: 'age', child: Text('Age')),
                        DropdownMenuItem(value: 'identity', child: Text('Identity')),
                        DropdownMenuItem(value: 'chatter_kyc', child: Text('Chatter KYC')),
                      ],
                      onChanged: (v) => setState(() => _kind = v ?? 'chatter_kyc'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _url,
                      decoration: const InputDecoration(
                        hintText: 'Document URL',
                        helperText: 'Use media upload endpoint, then paste the returned URL',
                      ),
                    ),
                    const SizedBox(height: 12),
                    PillButton.primary(
                      onTap: _submitting ? null : _submit,
                      height: 48,
                      child: Text(_submitting ? 'Submitting…' : 'Submit'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Your submissions'),
              if (items.isEmpty)
                const Text('No submissions yet.', style: TextStyle(color: MtaaniColors.muted))
              else
                for (final raw in items)
                  if (raw is Map)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color: '${raw['status']}' == 'approved'
                                  ? MtaaniColors.like
                                  : MtaaniColors.coralDeep,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${raw['kind'] ?? 'Verification'}',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '${raw['status'] ?? 'pending'}',
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
