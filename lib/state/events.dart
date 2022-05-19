import 'package:alt_alpha/model/alt_alpha.dart';
import 'package:alt_alpha/state/alt_alpha_device.dart';

abstract class Event {}

class Inited extends Event {}

class ConnectRequest extends Event {
  final AltAlphaDevice device;
  ConnectRequest(this.device);
}

class DisconnectRequest extends Event {}

class ConnectFailed extends Event {}

class Connected extends Event {
  final AltAlphaDevice device;
  Connected(this.device);
}

class Disconnected extends Event {}

class LiveSampleUpdated extends Event {
  final List<LiveSample> sample;
  LiveSampleUpdated(this.sample);
}
