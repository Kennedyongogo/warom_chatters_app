import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/social.dart';
import '../../services/mtaani_api.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';
import 'account_steps.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  int _checked = 0;
  bool _done = false;
  String? _error;

  List<String> get _checks {
    final account = MtaaniApi.instance.account!;
    return [
      'Signed in with ${account.provider.label}',
      'Terms accepted (v${account.termsVersion ?? MtaaniApi.termsVersion})',
      'Age confirmed 18+',
      'Photos reviewed',
      'Profile complete',
    ];
  }

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _checked = 0;
      _error = null;
    });
    final activation = MtaaniApi.instance.activateProfile().then<Object?>((_) => null, onError: (Object e) => e);
    for (var i = 0; i < _checks.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _checked = i + 1);
    }
    final error = await activation;
    if (!mounted) return;
    if (error == null) {
      HapticFeedback.mediumImpact();
      setState(() => _done = true);
    } else if (error is ApiException && error.code == ApiException.ineligible) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const IneligiblePage()), (_) => false);
    } else {
      setState(() {
        _checked = 0;
        _error = error is ApiException ? error.message : 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = MtaaniApi.instance.me!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _done
                    ? Avatar(key: const ValueKey('avatar'), profile: me, size: 100, ring: true)
                    : const HeartMark(key: ValueKey('heart'), size: 72),
              ),
              const SizedBox(height: 18),
              Text(
                _done
                    ? 'You\'re all set, ${me.firstName}!'
                    : (_error == null ? 'Getting you ready…' : 'Almost there'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: MtaaniColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                _done
                    ? 'Your profile is live. People nearby can now discover you.'
                    : (_error ?? 'We run a few final checks before anyone can see your profile.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: _error != null ? MtaaniColors.coralDeep : MtaaniColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < _checks.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: i < _checked
                            ? const Icon(Icons.check_circle_rounded, key: ValueKey('ok'), color: MtaaniColors.like)
                            : (i == _checked && _error == null
                                ? const SizedBox.square(
                                    key: ValueKey('busy'),
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: MtaaniColors.coralDeep,
                                    ),
                                  )
                                : const Icon(
                                    Icons.radio_button_unchecked_rounded,
                                    key: ValueKey('todo'),
                                    color: MtaaniColors.line,
                                  )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _checks[i],
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: i < _checked ? MtaaniColors.ink : MtaaniColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              if (_done)
                PillButton.primary(
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeShell()),
                    (_) => false,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start discovering'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                )
              else if (_error != null)
                PillButton.primary(onTap: _run, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
