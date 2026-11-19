import 'package:flutter/material.dart';

import '../../services/mtaani_api.dart';
import '../../services/warom_api.dart';
import '../../services/warom_auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../landing/landing_page.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_confirm.text.trim().toUpperCase() != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type DELETE to confirm')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await WaromApi.instance.deleteAccount();
      await WaromAuth.instance.clear();
      MtaaniApi.instance.logOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          const Text(
            'This permanently deletes your chatter account, chats, and earnings access. This cannot be undone.',
            style: TextStyle(height: 1.45, color: MtaaniColors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirm,
            decoration: const InputDecoration(labelText: 'Type DELETE to confirm'),
          ),
          const SizedBox(height: 20),
          PillButton(
            onTap: _busy ? null : _delete,
            color: const Color(0xFFB42318),
            child: Text(_busy ? 'Deleting…' : 'Delete my account'),
          ),
        ],
      ),
    );
  }
}
