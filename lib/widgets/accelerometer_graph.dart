import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:alt_alpha/widgets/simple_graph.dart';
import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

class AccelerometerGraph extends StatelessWidget {
  const AccelerometerGraph({Key? key, required this.list}) : super(key: key);

  final List<FetchSample> list;

  @override
  Widget build(BuildContext context) => [
        'Accelerometer - Recorded'.wText.center,
        SimpleGraph(list: list.map((update) => update.force).toList()),
      ].column;
}
