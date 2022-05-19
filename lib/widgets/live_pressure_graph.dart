import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:alt_alpha/widgets/simple_graph.dart';
import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

// static float pressureToAltitude(float seaLevel, float atmospheric, float temp);

// From: https://github.com/adafruit/Adafruit_BMP085_Unified/blob/master/Adafruit_BMP085_U.cpp#L361-L371
// Equation taken from BMP180 datasheet (page 16): http://www.adafruit.com/datasheets/BST-BMP180-DS000-09.pdf
// static float pressureToAltitude(float seaLevel, float atmospheric) {
//   return 44330.0 * (1.0 - pow(atmospheric / seaLevel, 0.1903));
// }

class LivePressureGraph extends StatelessWidget {
  const LivePressureGraph({Key? key, required this.device}) : super(key: key);

  final AltAlphaDevice device;

  @override
  Widget build(BuildContext context) => [
        'Pressure - Live'.wText.center,
        StreamBuilder<List<LiveSample>>(
          initialData: device.liveSamples,
          stream: device.liveSamplesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            return SimpleGraph(list: snapshot.data!.map((update) => update.airpressure).toList());
          },
        ),
      ].column;
}
