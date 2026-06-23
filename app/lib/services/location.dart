import 'package:location/location.dart';

final location = Location();

Future<bool> _isLocationServiceEnabled() async {
  final serviceEnabled = await location.serviceEnabled();
  if (!serviceEnabled) {
    return await location.requestService();
  }
  return true;
}

Future<bool> hasLocationPermission() async {
  return await _isLocationServiceEnabled() &&
      await location.hasPermission() == PermissionStatus.granted;
}

Future<bool> requestLocationPermission() async {
  if (await _isLocationServiceEnabled() == false) return false;

  return await location.requestPermission() == PermissionStatus.granted;
}

Future<bool> canRequestLocationPermission() async {
  if (await _isLocationServiceEnabled() == false) return false;

  final permissionGranted = await location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    return await location.requestPermission() == PermissionStatus.granted;
  }

  return true;
}

Future<LocationData?> getUserLocation() async {
  if (await hasLocationPermission() == false) return null;

  // Ensures high accuracy
  await location.changeSettings(accuracy: LocationAccuracy.high);
  return await location.getLocation();
}
