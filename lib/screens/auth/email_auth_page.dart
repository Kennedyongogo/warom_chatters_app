import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../services/call_launcher.dart';
import '../../services/mtaani_api.dart';
import '../../services/warom_api.dart';
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

  Future<void> _forgotPassword() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => _ResetPasswordSheet(initialEmail: _email.text.trim()),
    );
    if (!mounted || result == null) return;
    if (result.isNotEmpty) _email.text = result;
    showSuccessSnack(context, 'Reset link sent to $result');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      WaromSession session;
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

      // Re-read /auth/me so onboarding_completed is fresh from the server.
      try {
        session = await WaromAuth.instance.refreshMe();
      } catch (_) {
        // Keep login/register payload if /me is briefly unavailable.
      }

      // Create → onboarding once. Login → always Home (never re-trap in Terms).
      MtaaniApi.instance.adoptRemoteUser(
        user: session.user,
        provider: AuthProvider.email,
        isNew: _creating,
        skipOnboarding: !_creating,
      );

      if (!_creating && !session.onboardingCompleted) {
        // Returning users should not be blocked; sync the flag in the background.
        WaromApi.instance.updateMe({'onboarding_completed': true}).then((remote) {
          WaromAuth.instance.mergeUser({...remote, 'onboarding_completed': true});
        }).catchError((_) {});
      }

      if (!mounted) return;
      final welcome = _creating ? 'Account created — welcome to Warom' : 'Logged in successfully';
      enterApp(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navContext = CallLauncher.instance.navigatorKey?.currentContext;
        if (navContext != null && navContext.mounted) {
          showSuccessSnack(navContext, welcome);
        }
      });
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
              if (!_creating) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: MtaaniColors.coralDeep,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ],
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

class _ResetPasswordSheet extends StatefulWidget {
  final String initialEmail;

  const _ResetPasswordSheet({required this.initialEmail});

  @override
  State<_ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<_ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pop(context, _email.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    // Clear visual separation from the keyboard / home indicator.
    const gap = 14.0;
    final bottomPad = keyboard > 0 ? keyboard + gap : bottomSafe + gap;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad),
      child: Material(
        color: Colors.white,
        elevation: 12,
        shadowColor: MtaaniColors.ink.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: MtaaniColors.line,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: MtaaniColors.blush,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: MtaaniColors.coralDeep,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset password',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: MtaaniColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'We’ll send a reset link to your email.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: MtaaniColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: widget.initialEmail.isEmpty,
                  enabled: !_sending,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@email.com',
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    filled: true,
                    fillColor: MtaaniColors.canvas,
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
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (!EmailValidator.validate(v)) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _sending ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: MtaaniColors.muted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: MtaaniColors.line),
                          ),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _sending ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: MtaaniColors.coralDeep,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: MtaaniColors.coralDeep.withValues(alpha: 0.55),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send link',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
