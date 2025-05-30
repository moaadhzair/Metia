// main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:metia/pages/home_page.dart';

// Import conditionally based on platform
import 'package:metia/conflict/register_custom_scheme_stub.dart'
    if (dart.library.io) 'package:metia/conflict/register_custom_scheme_windows.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  //await windowManager.ensureInitialized();

  if (Platform.isWindows) {
    registerCustomScheme('metia');
  }
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
