import 'package:geolocator/geolocator.dart';

enum LocationProblem { serviceOff, denied, deniedForever, unavailable }

class LocationException implements Exception {
  LocationException(this.message, [this.problem = LocationProblem.unavailable]);
  final String message;
  final LocationProblem problem;

  /// GPS off or permission blocked: the user must fix it in system settings.
  bool get needsSettings =>
      problem == LocationProblem.serviceOff || problem == LocationProblem.deniedForever;

  @override
  String toString() => message;
}

class LocationService {
  /// Checks GPS is on and permission granted, then returns the current position.
  /// Throws [LocationException] with a user-friendly message otherwise.
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocationException(
        'Location is turned off. Please enable GPS.',
        LocationProblem.serviceOff,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException(
        'Location permission denied. ClassTrack needs it to check you are in class.',
        LocationProblem.denied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is blocked. Enable it from app settings.',
        LocationProblem.deniedForever,
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      throw LocationException(
        'Could not get a GPS fix. Move near a window and try again.',
        LocationProblem.unavailable,
      );
    }
  }

  /// Opens the right system screen for [problem].
  Future<void> openSettings(LocationProblem problem) async {
    if (problem == LocationProblem.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
