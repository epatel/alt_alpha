import 'package:alt_alpha/pages/connected_page.dart';
import 'package:alt_alpha/pages/connecting_page.dart';
import 'package:alt_alpha/pages/scan_page.dart';
import 'package:alt_alpha/state/alt_alpha_device.dart';
import 'package:alt_alpha/widgets/widget_stream.dart';
import 'package:flutter/material.dart';

import 'events.dart';

class EventHandler {
  final WidgetStream _mainWidgetStream;

  EventHandler(this._mainWidgetStream);

  AltAlphaDevice? device;

  void handleEvent(Event event) {
    switch (event.runtimeType) {
      case Inited:
      case ConnectFailed:
      case Disconnected:
      case DisconnectRequest:
        device?.dispose();
        device = null;
        _mainWidgetStream.goto(const ScanPage());
        break;

      case ConnectRequest:
        if (event is ConnectRequest) {
          device = event.device;
          device!.connect().onError((error, stackTrace) {
            debugPrint('########## Error on connect!');
            handleEvent(Disconnected());
          });
          _mainWidgetStream.goto(ConnectingPage(device: device!));
        }
        break;

      case Connected:
        _mainWidgetStream.goto(ConnectedPage(device: device!));
        break;

      default:
    }
  }
}
