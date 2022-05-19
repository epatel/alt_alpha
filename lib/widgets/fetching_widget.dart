import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

class FetchingWidget extends StatefulWidget {
  const FetchingWidget({Key? key, required this.device}) : super(key: key);

  final AltAlphaDevice device;

  @override
  State<FetchingWidget> createState() => _FetchingWidgetState();
}

class _FetchingWidgetState extends State<FetchingWidget> {
  AltAlphaDevice get device => widget.device;

  var currentSampleIndex = 99999; // Counting down
  var maxNumberOfSamples = 99999;

  @override
  Widget build(BuildContext context) {
    return [
      'Fetching...'.wText,
      quickLargeFiller(),
      quickLargeFiller(),
      SizedBox(
        width: 30,
        height: 30,
        child: StreamBuilder<int>(
          stream: device.fetchSamplesStream.map((sample) => sample.index),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              currentSampleIndex = snapshot.data!;
              if (maxNumberOfSamples == 99999) {
                maxNumberOfSamples = currentSampleIndex;
              }
            }
            return CircularProgressIndicator(
              value: 1 - currentSampleIndex / maxNumberOfSamples,
              strokeWidth: 30,
            );
          },
        ),
      ),
    ].columnCentered.center;
  }
}
