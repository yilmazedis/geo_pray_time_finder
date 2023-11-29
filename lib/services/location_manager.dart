import 'package:location/location.dart';

class GeoService {
  final Location _location = Location();

  Future<bool> isLocationServiceEnabled() async {
    bool serviceEnabled = await _location.serviceEnabled();
    return serviceEnabled;
  }

  Future<void> requestLocationService() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _location.requestService();
    }
  }

  Future<bool> hasLocationPermission() async {
    PermissionStatus permissionStatus = await _location.hasPermission();
    return permissionStatus == PermissionStatus.granted;
  }

  Future<void> requestLocationPermission() async {
    bool hasPermission = await hasLocationPermission();
    if (!hasPermission) {
      await _location.requestPermission();
    }
  }

  Future<Map<String, double>> getLocation() async {
    try {
      await requestLocationService();
      await requestLocationPermission();

      LocationData locationData = await _location.getLocation();
      double latitude = locationData.latitude ?? 0.0;
      double longitude = locationData.longitude ?? 0.0;

      return {'latitude': latitude, 'longitude': longitude};
    } catch (e) {
      print('Error getting location: $e');
      return {'latitude': 0.0, 'longitude': 0.0};
    }
  }
}
