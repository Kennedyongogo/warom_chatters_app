import 'package:flutter/material.dart';

import 'screens/landing/landing_page.dart';
import 'services/call_launcher.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> waromNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Hold the first frame so the launch screen stays up until the landing photo is decoded.
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  CallLauncher.instance.attach(waromNavigatorKey);
  runApp(const MtaaniApp());
}

class MtaaniApp extends StatelessWidget {
  const MtaaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warom chatters',
      navigatorKey: waromNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildMtaaniTheme(),
      home: const _FirstFrameGate(child: LandingPage()),
    );
  }
}

class _FirstFrameGate extends StatefulWidget {
  final Widget child;

  const _FirstFrameGate({required this.child});

  @override
  State<_FirstFrameGate> createState() => _FirstFrameGateState();
}

class _FirstFrameGateState extends State<_FirstFrameGate> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    precacheImage(LandingPage.background, context)
        .timeout(const Duration(seconds: 3), onTimeout: () {})
        .whenComplete(WidgetsBinding.instance.allowFirstFrame);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
