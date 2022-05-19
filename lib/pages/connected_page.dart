import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:alt_alpha/state/app.dart';
import 'package:alt_alpha/state/events.dart';
import 'package:alt_alpha/widgets/accelerometer_graph.dart';
import 'package:alt_alpha/widgets/fetching_widget.dart';
import 'package:alt_alpha/widgets/live_accelerometer_graph.dart';
import 'package:alt_alpha/widgets/live_pressure_graph.dart';
import 'package:alt_alpha/widgets/pressure_graph.dart';
import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

class ConnectedPage extends StatefulWidget {
  const ConnectedPage({Key? key, required this.device}) : super(key: key);

  final AltAlphaDevice device;

  @override
  State<ConnectedPage> createState() => _ConnectedPageState();
}

class _ConnectedPageState extends State<ConnectedPage> {
  AltAlphaDevice get device => widget.device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 'Connected'.wText,
        leading: Icons.close.icon.onTap(() {
          App.instance.eventHandler.handleEvent(DisconnectRequest());
        }),
      ),
      body: [
        ConnectedWidget(device: device),
      ].columnCentered.center,
    ).safeArea;
  }
}

// -----------------------------------------------------------------------------

class ConnectedWidget extends StatefulWidget {
  const ConnectedWidget({Key? key, required this.device}) : super(key: key);

  final AltAlphaDevice device;

  @override
  State<ConnectedWidget> createState() => ConnectedWidgetState();
}

class ConnectedWidgetState extends State<ConnectedWidget> {
  AltAlphaDevice get device => widget.device;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AltAlphaState>(
        initialData: device.currentState,
        stream: device.stateStream,
        builder: (context, snapshot) => [
              _dataView(snapshot.data!),
              quickLargeFiller(),
              _buttons(snapshot.data!),
            ].column.center.largePadding);
  }

  Widget _startLiveButton() => [
        Icons.play_arrow.white.icon,
        quickSmallFiller(),
        'Start Live'.wText,
      ].rowMin.button(() {
        device.sendCommand(AltAlphaCommand.liveStart);
      });

  Widget _startRecordButton() => [
        Icons.circle.white.smallIcon,
        quickSmallFiller(),
        'Start Record'.wText,
      ].rowMin.button(() {
        device.sendCommand(AltAlphaCommand.recordStart);
      });

  Widget _fasterButton() => [
        Icons.fast_forward.white.icon,
        quickSmallFiller(),
        'Faster'.wText,
      ].rowMin.button(() {
        device.sendCommand(AltAlphaCommand.liveStart);
      });

  Widget _stopLiveButton() => [
        Icons.rectangle.white.smallIcon,
        quickSmallFiller(),
        'Stop Live'.wText,
      ].rowMin.button(() {
        device.sendCommand(AltAlphaCommand.liveStop);
      });

  Widget _startFetchButton() => [
        Icons.download.white.smallIcon,
        quickSmallFiller(),
        'Start Fetch'.wText,
      ].rowMin.button(() {
        device.sendCommand(AltAlphaCommand.recordFetch);
      });

  Widget _stopFetchButton() => [
        Icons.rectangle.white.smallIcon,
        quickSmallFiller(),
        'Stop Fetch'.wText,
      ].rowMin.button(() {
        device.sendCommand(AltAlphaCommand.recordDone);
      });

  Widget _closeButton() => [
        Icons.close.white.smallIcon,
        quickSmallFiller(),
        'Close'.wText,
      ].rowMin.button(() {
        App.instance.eventHandler.handleEvent(DisconnectRequest());
      });

  // For test of error state
  // Widget _errorButton() => 'Error'.wText.button(() {
  //       device.sendCommand(AltAlphaCommand.error);
  //     });

  Widget _buttons(AltAlphaState state) {
    switch (state) {
      case AltAlphaState.unknown:
        return [
          'Unknown state'.wText.center.expanded,
        ].rowSpread.largePadding;

      case AltAlphaState.idle:
        return [
          _startLiveButton().expanded,
          quickMediumFiller(),
          _startRecordButton().expanded,
        ].rowSpread.largePadding;

      case AltAlphaState.live:
        return [
          _fasterButton().expanded,
          quickMediumFiller(),
          _stopLiveButton().expanded,
        ].rowSpread.largePadding;

      case AltAlphaState.record:
        return [
          _startFetchButton().center.expanded,
          quickMediumFiller(),
          _closeButton().center.expanded,
        ].rowSpread.largePadding;

      case AltAlphaState.fetch:
        return [
          _stopFetchButton().center.expanded,
        ].rowSpread.largePadding;

      default:
        return [
          _closeButton().center.expanded,
        ].rowSpread.largePadding;
    }
  }

  Widget _dataView(AltAlphaState state) {
    switch (state) {
      case AltAlphaState.live:
        return PageView.builder(
          itemCount: 2,
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return LiveAccelerometerGraph(device: device);
              case 1:
                return LivePressureGraph(device: device);
              default:
            }
            return const CircularProgressIndicator();
          },
        ).square;
      case AltAlphaState.record:
        return 'Recording...'.wText.center.square;
      case AltAlphaState.fetch:
        return FetchingWidget(device: device).square;
      case AltAlphaState.idle:
        if (device.recordedSamples.isNotEmpty) {
          return PageView.builder(
            itemCount: 2,
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return AccelerometerGraph(list: device.recordedSamples);
                case 1:
                  return PressureGraph(list: device.recordedSamples);
                default:
              }
              return const CircularProgressIndicator();
            },
          ).square;
        } else {
          return Container().square;
        }
      default:
        return Container().square;
    }
  }
}
