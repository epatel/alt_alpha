import 'dart:async';

import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:alt_alpha/model/sensor.dart';
import 'package:alt_alpha/state/app.dart';
import 'package:alt_alpha/state/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:qidgets/qidgets.dart';

class AltAlphaDevice {
  final BluetoothDevice _device;

  StreamSubscription<BluetoothDeviceState>? _connectionListener;

  final _commandSensor = Sensor<AltAlphaCommand>(commandUUID);
  final _stateSensor = Sensor<AltAlphaState>(stateUUID);
  final _liveSensor = Sensor<LiveSample>(liveUUID);
  final _fetchSensor = Sensor<FetchSample>(fetchUUID);

  final _setupStreamController = StreamController<int>.broadcast();
  final _stateStreamController = StreamController<AltAlphaState>.broadcast();
  final _liveSamplesStreamController = StreamController<LiveSample>.broadcast();
  final _fetchSamplesStreamController = StreamController<FetchSample>.broadcast();
  var currentState = AltAlphaState.unknown;
  static const _liveListMaxLen = 120;
  final _liveList = <LiveSample>[];
  final _recordedList = <FetchSample>[];
  Stream<int> get setupStream => _setupStreamController.stream;
  Stream<AltAlphaState> get stateStream => _stateStreamController.stream;
  Stream<List<LiveSample>> get liveSamplesStream =>
      _liveSamplesStreamController.stream.map((sample) => _sampleList(sample));
  Stream<FetchSample> get fetchSamplesStream => _fetchSamplesStreamController.stream;

  List<LiveSample> get liveSamples => _liveList;
  List<FetchSample> get recordedSamples => _recordedList;

  AltAlphaDevice(this._device);

  bool abort = false;

  void dispose() {
    abort = true;
    _connectionListener?.cancel();
    _commandSensor.dispose();
    _stateSensor.dispose();
    _liveSensor.dispose();
    _fetchSensor.dispose();
    _setupStreamController.close();
    _stateStreamController.close();
    _liveSamplesStreamController.close();
    _device.disconnect();
  }

  Future<void> connect() async {
    try {
      await _device.connect(timeout: quickDuration10sec, autoConnect: false);
      if (abort) return;
      await _setup();
      App.instance.eventHandler.handleEvent(Connected(this));
    } catch (e) {
      App.instance.eventHandler.handleEvent(ConnectFailed());
    }
  }

  Future<void> _setup() async {
    currentState = AltAlphaState.unknown;
    _setupStreamController.sink.add(10); // Let say this is 10%
    if (abort) return;
    _connectionListener = _device.state.listen((state) {
      switch (state) {
        case BluetoothDeviceState.disconnecting:
        case BluetoothDeviceState.disconnected:
          App.instance.eventHandler.handleEvent(Disconnected());
          break;
        default:
      }
    });
    final services = await _device.discoverServices();
    if (abort) return;
    _setupStreamController.sink.add(20); // Let say this is 20%
    for (final service in services) {
      if (service.uuid.toString().toUpperCase() == serviceUUID) {
        final numCharacteristics = service.characteristics.length;
        int progress = 0;
        for (final characteristic in service.characteristics) {
          progress++;
          // Let say this from 20% to 100%
          _setupStreamController.sink.add(20 + 80 * progress ~/ numCharacteristics);
          await _commandSensor.setIf(characteristic);
          await _stateSensor.setIf(characteristic, (sensor) {
            debugPrint('##### State: ${sensor.value.name}');
            currentState = sensor.value;
            if (_stateStreamController.isClosed) return;
            _stateStreamController.sink.add(sensor.value);
          });
          await _liveSensor.setIf(characteristic, (sensor) {
            //debugPrint('##### LiveSample');
            if (_liveSamplesStreamController.isClosed) return;
            _liveSamplesStreamController.sink.add(sensor.value);
          });
          await _fetchSensor.setIf(characteristic, (sensor) {
            //debugPrint('##### FetchSample: ${sensor.value.index} ${sensor.value.force} ${sensor.value.airpressure}');
            if (_fetchSamplesStreamController.isClosed) return;
            _recordedList.insert(0, sensor.value);
            _fetchSamplesStreamController.sink.add(sensor.value);
          });
          if (abort) return;
        }
      }
    }
    if (abort) return;
    sendCommand(AltAlphaCommand.queryState);
  }

  void sendCommand(AltAlphaCommand command) {
    if (command == AltAlphaCommand.recordFetch) {
      _recordedList.clear();
    }
    _commandSensor.write(command.index);
  }

  List<LiveSample> _sampleList(LiveSample sample) {
    _liveList.add(sample);
    if (_liveList.length > _liveListMaxLen) {
      _liveList.removeRange(0, _liveList.length - _liveListMaxLen);
    } else if (_liveList.isNotEmpty && _liveList.length < _liveListMaxLen) {
      final firstValue = _liveList.first;
      _liveList.insertAll(0, List<LiveSample>.generate(_liveListMaxLen - _liveList.length, (index) => firstValue));
    }
    return _liveList;
  }
}
