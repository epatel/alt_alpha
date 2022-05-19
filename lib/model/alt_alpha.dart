import 'dart:typed_data';

// echo phrase | xxd > UUID
// echo 0:UUID | xxd -r
const serviceUUID = "65706174-656C-2E61-6C70-68612E626C65";
const commandUUID = "65706174-656C-2E62-6C65-2E636D642E2E";
const stateUUID = "65706174-656C-2E62-6C65-2E7374617465";
const liveUUID = "65706174-656C-2E62-6C65-2E6C6976652E";
const fetchUUID = "65706174-656C-2E62-6C65-2E6665746368";

enum AltAlphaState {
  init, // 0
  idle, // 1
  live, // 2
  record, // 3
  fetch, // 4
  error, // 5
  unknown, // App only
}

enum AltAlphaCommand {
  queryState, // 0
  recordStart, // 1
  recordAbort, // 2
  recordFetch, // 3
  recordDone, // 4
  liveStart, // 5
  liveStop, // 6
  error, // 7
}

class LiveSample {
  LiveSample(this.force, this.airpressure);
  double force;
  double airpressure;

  static LiveSample decode(ByteData byteData) {
    final force = byteData.getUint16(0, Endian.little);
    final airpressure = byteData.getUint16(2, Endian.little);
    return LiveSample(50.0 * force / 0xffff, 600 + (600 * airpressure) / 0xffff);
  }
}

class FetchSample {
  FetchSample(this.index, this.force, this.airpressure);
  int index;
  double force;
  double airpressure;

  static FetchSample decode(ByteData byteData) {
    final index = byteData.getUint16(0, Endian.little);
    final force = byteData.getUint16(2, Endian.little);
    final airpressure = byteData.getUint16(4, Endian.little);
    return FetchSample(index, 50.0 * force / 0xffff, 600 + (600 * airpressure) / 0xffff);
  }
}
