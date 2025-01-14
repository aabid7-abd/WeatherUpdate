import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

const  openWeatherApiKey ="your api key";
Future<String> getCityName() async {
  try {
    // Get current position (latitude and longitude)
    Position position = await getDeviceLocation();


    // Use the latitude and longitude to get the city name
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    // Extract the city from the placemarks
    String city = placemarks[0].locality ?? 'Unknown City';
    return city;
  } catch (e) {
    return 'Error: $e';
  }
}

Future<Position> getDeviceLocation() async {
  // Check if the location service is enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {

    throw Exception("Location services are disabled.");
  }

  // Check for location permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print("Location permission denied.");
      throw Exception("Location permission denied.");
    }
  }

  // Get the current position (latitude and longitude)
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  return position;
}