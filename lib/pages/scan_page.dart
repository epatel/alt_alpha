import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:alt_alpha/state/app.dart';
import 'package:alt_alpha/state/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:qidgets/qidgets.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  bool isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 'Alt Alpha'.wText,
      ),
      body: [
        StreamBuilder<List<ScanResult>>(
          stream: flutterBlue.scanResults,
          builder: (context, snapshot) {
            List<ScanResult> scanResults = [];
            if (snapshot.hasData) {
              scanResults =
                  snapshot.data!.where((item) => item.advertisementData.localName.startsWith('AltAlpha_')).toList();
              //scanResults = snapshot.data!.where((item) => true).toList();
            }
            return ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) => _listItem(context, scanResults[index]),
            );
          },
        ).black12.expanded,
        const Divider(),
        [
          _scanButton(),
        ].columnCentered.expanded,
      ].column.center,
    ).safeArea;
  }

  Widget _scanButton() {
    return StreamBuilder<bool>(
      stream: flutterBlue.isScanning,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!) {
          return 'Stop scanning'.wText.button(() {
            flutterBlue.stopScan();
          });
        } else {
          return 'Scan for device'.wText.button(() {
            flutterBlue.startScan(timeout: quickDuration10sec);
            flutterBlue.scanResults // Restart if nothing received during first 1sec
                .where((item) => item.isNotEmpty)
                .first
                .timeout(quickDuration1sec, onTimeout: (() {
              _restartScan();
              return [];
            }));
          });
        }
      },
    );
  }

  void _restartScan() async {
    debugPrint('########## Restart scan');
    await flutterBlue.stopScan();
    await Future.delayed(quickDuration100ms);
    await flutterBlue.startScan(timeout: quickDuration10sec);
  }

  Widget _listItem(BuildContext context, ScanResult item) => ListTile(
        title: item.advertisementData.localName.wText,
        trailing: Icons.chevron_right.icon,
        onTap: () {
          App.instance.eventHandler.handleEvent(ConnectRequest(AltAlphaDevice(item.device)));
        },
      );
}
