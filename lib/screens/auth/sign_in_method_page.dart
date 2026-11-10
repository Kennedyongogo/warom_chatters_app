import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_options.dart';
import '../onboarding/onboarding_flow.dart';
import 'phone_page.dart';

enum AuthMode { create, logIn }

class SignInMethodPage extends StatefulWidget {
  final AuthMode mode;

  const SignInMethodPage({super.key, required this.mode});

  @override
  State<SignInMethodPage> createState() => _SignInMethodPageState();
}

class _SignInMethodPageState extends State<SignInMethodPage> {
  AuthProvider? _busy;

  Future<void> _withProvider(AuthProvider provider) async {
    final email = 'demo.${provider.name}@mtaani.app';
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProviderIcon(provider: provider, size: 40),
              const SizedBox(height: 14),
              Text('Sign in to Mtaani with ${provider.label}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: MtaaniColors.line),
                ),
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(email, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Demo account'),
              ),
              const SizedBox(height: 12),
              Text(
                '${provider.label} will share your name and email address with Mtaani.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: MtaaniColors.muted),
              ),
              const SizedBox(height: 18),
              PillButton.primary(onTap: () => Navigator.pop(context, true), child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = provider);
    final ok = await guarded(context, () => MtaaniApi.instance.continueWithProvider(provider));
    if (!mounted) return;
    setState(() => _busy = null);
    if (ok) enterApp(context);
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.mode == AuthMode.create;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Demo options',
            icon: const Icon(Icons.science_outlined),
            onPressed: () => showDemoOptions(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            const Center(child: HeartMark(size: 64)),
            const SizedBox(height: 16),
            Text(
              creating ? 'Create your account' : 'Welcome back',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MtaaniColors.ink, letterSpacing: -0.4),
            ),
            const SizedBox(height: 8),
            Text(
              creating ? 'Choose how you\'d like to sign up.' : 'Log in the same way you signed up.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: MtaaniColors.muted),
            ),
            const SizedBox(height: 36),
            PillButton.primary(
              onTap: _busy != null
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhonePage(mode: widget.mode))),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_iphone_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('Continue with phone number'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final provider in const [AuthProvider.google, AuthProvider.apple]) ...[
              PillButton(
                color: provider == AuthProvider.apple ? Colors.black : Colors.white,
                foreground: provider == AuthProvider.apple ? Colors.white : MtaaniColors.ink,
                border: provider == AuthProvider.google ? Border.all(color: MtaaniColors.line, width: 1.4) : null,
                onTap: _busy != null ? null : () => _withProvider(provider),
                child: _busy == provider
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ProviderIcon(provider: provider, size: 22),
                          const SizedBox(width: 10),
                          Text('Continue with ${provider.label}'),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: MtaaniColors.blush, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: MtaaniColors.coralDeep, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo: log in with 0712 345 678 to use Juma\'s finished account. Every code is ${MtaaniApi.demoCode}.',
                      style: TextStyle(fontSize: 13.5, color: MtaaniColors.ink, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'You\'ll review our Terms of Use and Privacy Policy before your profile goes live. '
              'We never post anything on your behalf.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: MtaaniColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderIcon extends StatelessWidget {
  final AuthProvider provider;
  final double size;

  const _ProviderIcon({required this.provider, required this.size});

  @override
  Widget build(BuildContext context) {
    if (provider == AuthProvider.apple) return Icon(Icons.apple, size: size * 1.1);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => const SweepGradient(
        colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
      ).createShader(b),
      child: Text('G', style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, height: 1)),
    );
  }
}
