import 'package:alt_alpha/state/event_handler.dart';
import 'package:alt_alpha/state/events.dart';
import 'package:alt_alpha/widgets/widget_stream.dart';
import 'package:flutter/material.dart';

class App {
  static final instance = App._();
  App._() {
    widgetStream = WidgetStream();
    eventHandler = EventHandler(widgetStream);
  }

  late WidgetStream widgetStream;
  late EventHandler eventHandler;

  Widget get mainWidget => widgetStream.widget;

  void init(Future<void> init) {
    widgetStream.init(init.then((_) {
      eventHandler.handleEvent(Inited());
    }));
  }
}
