import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/account.dart';
import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../onboarding/onboarding_flow.dart';
import 'sign_in_method_page.dart';

class OtpPage extends StatefulWidget {
  final OtpTicket ticket;
  final AuthMode mode;

  const OtpPage({super.key, required this.ticket, required this.mode});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _code = TextEditingController();
  final _api = MtaaniApi.instance;
  late OtpTicket _ticket = widget.ticket;
  Timer? _ticker;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  int get _resendIn => _ticket.resendAvailableAt.difference(DateTime.now()).inSeconds.clamp(0, 999);

  String get _prettyPhone {
    final p = _ticket.phone;
    return p.length < 10 ? p : '${p.substring(0, 4)} ${p.substring(4, 7)} ${p.substring(7, 10)} ${p.substring(10)}';
  }

  Future<void> _verify({bool createIfMissing = false}) async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await _api.verifyPhoneCode(
        _ticket.phone,
        _code.text,
        createIfMissing: createIfMissing || widget.mode == AuthMode.create,
      );
      if (!mounted) return;
      if (widget.mode == AuthMode.create && !outcome.isNewAccount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This number already has an account, so we\'ve logged you in.')),
        );
      }
      enterApp(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiException.noAccount) {
        setState(() => _busy = false);
        final create = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('No account found'),
            content: Text('There\'s no Mtaani account on $_prettyPhone yet. Would you like to create one?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: MtaaniColors.coralDeep),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create account'),
              ),
            ],
          ),
        );
        if (create == true) await _verify(createIfMissing: true);
        return;
      }
      setState(() => _error = e.message);
      _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      final ticket = await _api.requestPhoneCode(_ticket.phone);
      if (!mounted) return;
      setState(() {
        _ticket = ticket;
        _error = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('A new code is on its way.')));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            const Text('Enter your code',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink, letterSpacing: -0.4)),
            const SizedBox(height: 8),
            Text('We sent a 6-digit code to $_prettyPhone.',
                style: const TextStyle(fontSize: 15, color: MtaaniColors.muted, height: 1.4)),
            const SizedBox(height: 28),
            TextField(
              controller: _code,
              autofocus: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 30, letterSpacing: 16, fontWeight: FontWeight.w800),
              onChanged: (v) {
                if (_error != null) setState(() => _error = null);
                if (v.length == 6) _verify();
              },
              decoration: InputDecoration(counterText: '', hintText: '••••••', errorText: _error, errorMaxLines: 2),
            ),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(color: MtaaniColors.coralDeep, backgroundColor: MtaaniColors.line),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _resendIn > 0 ? null : _resend,
                  child: Text(_resendIn > 0 ? 'Resend code in ${_resendIn}s' : 'Resend code'),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Change number')),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: MtaaniColors.blush, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: MtaaniColors.coralDeep, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Demo: no SMS is sent. The code is ${MtaaniApi.demoCode}.',
                        style: TextStyle(fontSize: 13.5, color: MtaaniColors.ink)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
