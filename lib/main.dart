import 'package:alt_alpha/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/app.dart';

void main() {
  runApp(const AltAlphaApp());
}

class AltAlphaApp extends StatelessWidget {
  const AltAlphaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    App.instance.init(_init());
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alt Alpha',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: App.instance.mainWidget,
    );
  }

  Future<void> _init() async {
    // Prepare anything before sending Inited to state machine
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await Storage.instance.init();
  }
}
