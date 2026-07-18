import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'state/app_state.dart';

class DisplayVisionApp extends StatelessWidget {
  const DisplayVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AppState, bool>((s) => s.signedIn);
    return MaterialApp(
      title: 'DisplayVision',
      debugShowCheckedModeBanner: false,
      theme: DVTheme.dark(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        child: signedIn ? const HomeShell() : const LoginScreen(),
      ),
    );
  }
}
