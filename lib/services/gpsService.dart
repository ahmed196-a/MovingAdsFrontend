import 'dart:async';
import 'package:geolocator/geolocator.dart';
/// Singleton GPS service.
/// - fetchOnce()       → one-shot position (used at vehicle link time)
/// - startPinging()    → periodic stream every [intervalSeconds] seconds
/// - stopPinging()     → cancels the timer
class GpsService {
  GpsService._();
  static final GpsService instance = GpsService._();

  Timer? _pingTimer;
  bool get isPinging => _pingTimer != null && _pingTimer!.isActive;

  // ── ONE-SHOT ────────────────────────────────────────────────────────────────
  /// Returns the driver's current location.
  /// Requests permission if needed. Throws a descriptive string on failure.
  Future<Position> fetchOnce() async {
    await _ensurePermission();
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ── PERIODIC PING LOOP ──────────────────────────────────────────────────────
  /// Starts calling [onPing] every [intervalSeconds] seconds with the
  /// latest position. Fires the first ping immediately.
  /// Call [stopPinging] to cancel.
  void startPinging({
    required int intervalSeconds,
    required void Function(Position position) onPing,
    required void Function(String error) onError,
  }) {
    stopPinging(); // cancel any existing timer

    Future<void> doPing() async {
      try {
        final pos = await fetchOnce();
        onPing(pos);
      } catch (e) {
        onError(e.toString());
      }
    }

    doPing(); // immediate first ping
    _pingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
          (_) => doPing(),
    );
  }

  void stopPinging() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // ── PERMISSION HELPER ───────────────────────────────────────────────────────
  Future<void> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Please enable it in settings.';
    }
  }
}