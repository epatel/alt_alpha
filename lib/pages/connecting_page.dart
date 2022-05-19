import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

class ConnectingPage extends StatelessWidget {
  const ConnectingPage({Key? key, required this.device}) : super(key: key);

  final AltAlphaDevice device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        'Probing...'.wText,
        quickLargeFiller(),
        quickLargeFiller(),
        SizedBox(
          width: 30,
          height: 30,
          child: StreamBuilder<int>(
            initialData: 0,
            stream: device.setupStream,
            builder: ((context, snapshot) => CircularProgressIndicator(
                  value: snapshot.data! / 100.0,
                  strokeWidth: 30,
                )),
          ),
        ),
      ].columnCentered.center,
    );
  }
}
