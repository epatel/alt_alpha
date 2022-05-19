import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:alt_alpha/widgets/simple_graph.dart';
import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

class LiveAccelerometerGraph extends StatelessWidget {
  const LiveAccelerometerGraph({Key? key, required this.device}) : super(key: key);

  final AltAlphaDevice device;

  @override
  Widget build(BuildContext context) => [
        'Accelerometer - Live'.wText.center,
        StreamBuilder<List<LiveSample>>(
          initialData: device.liveSamples,
          stream: device.liveSamplesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return SimpleGraph(list: snapshot.data!.map((update) => update.force).toList());
          },
        ),
      ].column;
}
