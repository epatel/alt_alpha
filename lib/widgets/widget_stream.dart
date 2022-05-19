import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qidgets/qidgets.dart';

class WidgetStream {
  final streamController = StreamController<Widget>.broadcast();
  Future<void>? _init;
  Widget lastWidget = _spinner();

  Stream<Widget> get stream => streamController.stream;

  WidgetStream();

  void dispose() {
    streamController.close();
  }

  void goto(Widget widget) {
    lastWidget = widget;
    streamController.sink.add(widget);
  }

  Widget get widget => _init != null ? _futureWidget() : _streamWidget();

  Widget _futureWidget() => FutureBuilder(
        future: _init,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _init = null;
            return _streamWidget();
          }
          return _spinner();
        },
      );

  Widget _streamWidget() => StreamBuilder<Widget>(
        initialData: lastWidget,
        stream: stream,
        builder: (context, snapshot) {
          lastWidget = snapshot.data!;
          return lastWidget;
        },
      );

  static Widget _spinner() => Scaffold(
        body: const CircularProgressIndicator().center,
      );

  void init(Future<void> init) {
    _init = init;
  }
}
