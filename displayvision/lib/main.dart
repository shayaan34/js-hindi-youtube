import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.useFirebase) {
    // After running `flutterfire configure`, uncomment:
    //
    // import 'package:firebase_core/firebase_core.dart';
    // import 'firebase_options.dart';
    // await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform);
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const DisplayVisionApp(),
    ),
  );
}
