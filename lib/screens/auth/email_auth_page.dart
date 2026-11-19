import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../services/mtaani_api.dart';
import '../../services/warom_auth.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../onboarding/onboarding_flow.dart';
import 'sign_in_method_page.dart';

class EmailAuthPage extends StatefulWidget {
  final AuthMode mode;

  const EmailAuthPage({super.key, required this.mode});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _username = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _busy = false;

  bool get _creating => widget.mode == AuthMode.create;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final WaromSession session;
      if (_creating) {
        session = await WaromAuth.instance.register(
          email: _email.text,
          password: _password.text,
          username: _username.text,
        );
      } else {
        session = await WaromAuth.instance.login(
          email: _email.text,
          password: _password.text,
        );
      }

      MtaaniApi.instance.adoptRemoteUser(
        user: session.user,
        provider: AuthProvider.email,
        isNew: _creating || !session.onboardingCompleted,
      );

      if (!mounted) return;
      enterApp(context);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required Widget prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MtaaniColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MtaaniColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MtaaniColors.coral, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MtaaniColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: MtaaniColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: MtaaniColors.coral.withValues(alpha: 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(child: HeartMark(size: 36)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _creating ? 'Create your account' : 'Welcome back',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: MtaaniColors.ink,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _creating
                    ? 'Enter your details to get started on WAROM.'
                    : 'Log in with the email you used to sign up.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15.5, color: MtaaniColors.muted, height: 1.45),
              ),
              const SizedBox(height: 28),
              if (_creating) ...[
                TextFormField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: _fieldDecoration(
                    label: 'Username',
                    hint: 'How you appear on WAROM',
                    prefix: const Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.length < 3) return 'Username must be at least 3 characters';
                    if (v.length > 24) return 'Keep username under 24 characters';
                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                      return 'Use letters, numbers, dots or underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _fieldDecoration(
                  label: 'Email',
                  hint: 'you@email.com',
                  prefix: const Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (!EmailValidator.validate(v)) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: _creating ? TextInputAction.next : TextInputAction.done,
                autofillHints: [if (_creating) AutofillHints.newPassword else AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!_creating) _submit();
                },
                decoration: _fieldDecoration(
                  label: 'Password',
                  hint: '••••••••',
                  prefix: const Icon(Icons.lock_outline_rounded),
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) {
                  final v = value ?? '';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              if (_creating) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: _fieldDecoration(
                    label: 'Confirm password',
                    hint: '••••••••',
                    prefix: const Icon(Icons.lock_person_outlined),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value != _password.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              PillButton.primary(
                onTap: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(_creating ? 'Create account' : 'Log in'),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmailAuthPage(
                              mode: _creating ? AuthMode.logIn : AuthMode.create,
                            ),
                          ),
                        );
                      },
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(fontSize: 14.5, color: MtaaniColors.muted),
                    children: [
                      TextSpan(text: _creating ? 'Already have an account? ' : 'New here? '),
                      TextSpan(
                        text: _creating ? 'Log in' : 'Create an account',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: MtaaniColors.coralDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
