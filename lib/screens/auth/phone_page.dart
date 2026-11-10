import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'otp_page.dart';
import 'sign_in_method_page.dart';

class PhonePage extends StatefulWidget {
  final AuthMode mode;

  const PhonePage({super.key, required this.mode});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final _number = TextEditingController();
  Country _country = Country.supported.first;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = MtaaniApi.normalizePhone(_country, _number.text);
    if (phone == null) {
      setState(() => _error = 'Enter a valid ${_country.name} mobile number');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final ticket = await MtaaniApi.instance.requestPhoneCode(phone);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpPage(ticket: ticket, mode: widget.mode)));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  const Text('What\'s your number?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink, letterSpacing: -0.4)),
                  const SizedBox(height: 8),
                  const Text(
                    'We\'ll text you a 6-digit code to confirm it\'s yours. Your number is never shown on your profile.',
                    style: TextStyle(fontSize: 15, color: MtaaniColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<Country>(
                          initialValue: _country,
                          isExpanded: true,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                          items: [
                            for (final c in Country.supported)
                              DropdownMenuItem(value: c, child: Text('${c.flag} ${c.dialCode}')),
                          ],
                          onChanged: (c) => setState(() => _country = c ?? _country),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _number,
                          autofocus: true,
                          keyboardType: TextInputType.phone,
                          onSubmitted: (_) => _submit(),
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          decoration: InputDecoration(hintText: '712 345 678', errorText: _error, errorMaxLines: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sms_outlined, size: 16, color: MtaaniColors.muted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Standard SMS rates may apply. For your security we limit how many codes can be sent.',
                          style: TextStyle(fontSize: 13, color: MtaaniColors.muted, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: PillButton.primary(
                onTap: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Send code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
