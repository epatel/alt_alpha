import 'dart:async';
import 'dart:typed_data';

import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Sensor<T> {
  Sensor(this.uuid);

  String uuid;
  late T value;

  StreamSubscription? subscription;
  BluetoothCharacteristic? characteristic;

  void dispose() {
    subscription?.cancel();
    subscription = null;
    characteristic = null;
  }

  Future<void> write(int value) async {
    try {
      await characteristic?.write([value]);
    } catch (_) {}
  }

  Future<void> setIf(BluetoothCharacteristic characteristic, [void Function(Sensor<T> sensor)? updated]) async {
    if (this.characteristic == null && characteristic.uuid.toString().toUpperCase() == uuid) {
      this.characteristic = characteristic;
      if (updated != null) {
        await this.characteristic?.setNotifyValue(true);
        subscription = this.characteristic?.value.listen((data) {
          if (data.isEmpty) return;
          final bytes = Uint8List.fromList(data);
          final byteData = ByteData.sublistView(bytes);
          switch (T) {
            case AltAlphaState:
              value = AltAlphaState.values[byteData.getUint8(0)] as T;
              break;
            case LiveSample:
              value = LiveSample.decode(byteData) as T;
              break;
            case FetchSample:
              value = FetchSample.decode(byteData) as T;
              break;
            default:
              return;
          }
          updated(this);
        });
      }
    }
  }
}
