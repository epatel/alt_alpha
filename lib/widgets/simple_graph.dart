import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SimpleGraph extends StatelessWidget {
  const SimpleGraph({Key? key, required this.list}) : super(key: key);

  final List<double> list;

  @override
  Widget build(BuildContext context) => SfCartesianChart(
        series: <LineSeries<MapEntry<int, double>, int>>[
          LineSeries<MapEntry<int, double>, int>(
              animationDuration: 0.0,
              dataSource: list.asMap().entries.toList(),
              xValueMapper: (MapEntry<int, double> entry, _) => entry.key,
              yValueMapper: (MapEntry<int, double> entry, _) => entry.value)
        ],
      );
}
