import 'package:flutter/material.dart';

import '../../services/warom_api.dart';
import '../../widgets/common.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text != _confirm.text) {
      showWarnSnack(context, 'Passwords do not match');
      return;
    }
    if (_next.text.length < 8) {
      showWarnSnack(context, 'Use at least 8 characters');
      return;
    }
    setState(() => _saving = true);
    try {
      await WaromApi.instance.changePassword(current: _current.text, next: _next.text);
      if (mounted) {
        showSuccessSnack(context, 'Password updated');
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        children: [
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _next,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
          ),
          const SizedBox(height: 20),
          PillButton.primary(
            onTap: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Update password'),
          ),
        ],
      ),
    );
  }
}
