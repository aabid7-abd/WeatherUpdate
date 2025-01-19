import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:forecast/utility.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/weather.dart';

import 'Api.dart';

class WeatherProvider with ChangeNotifier {
  // Private Variables
  final WeatherFactory wf = WeatherFactory(openWeatherApiKey);
  String _city = "default";

  DateTime _cityLocalTime = DateTime.now();
  DateTime _citySunrise = DateTime.now();
  DateTime _citySunset = DateTime.now();

  String _unit = "°";
  String _forecastunit = "metric";
  Weather? _weather;
  String? _error;
  String? _cityerror;


  Map<String, dynamic>? _error2;
  final FocusNode _focusNode = FocusNode();
  List<dynamic>? _forecast;
  final Map<String, bool> _expandState = {};
  List<String> _recentSearches = [];
  bool _showRecentSearches = false;

  Weather? get weather => _weather;
  List? get forecast => _forecast;
  DateTime? get cityLocalTime => _cityLocalTime;
  DateTime? get citySunrise => _citySunrise;
  DateTime? get citySunset => _citySunset;
  String get city => _city;

  String get unit => _unit;
  String get forecastunit => _forecastunit;
  String? get error => _error;
  String? get cityerror => _cityerror;
  Map<String, dynamic>? get error2 => _error2;
  bool get showRecentSearches => _showRecentSearches;
  bool get isNight => _isNight();
  List<String> get recentSearches => _recentSearches;
  FocusNode? get focusNode => _focusNode;
  int _timezoneOffset = 0;
  int get timezoneOffset => _timezoneOffset;
  bool _isConnected = true;
  bool get isConnected => _isConnected;


  set isconnected(bool value) { // Setter to modify the value
    _isConnected = value;

    notifyListeners(); // Notify listeners if you're using ChangeNotifier
  }




  // Current weather function
  Future<void> fetchd() async {
    if(_isConnected){
      if (_city.isEmpty) return;
      try {

        // print("connect $_isConnected");
        // Continue with fetching weather data and timezone offset
        _weather = await wf.currentWeatherByCityName(_city);

        DateTime? d = _weather?.date;
        DateTime? s = _weather?.sunrise;
        DateTime? su = _weather?.sunset;

        // Fetch timezone offset from OpenWeather API
        final url = Uri.parse(
            "https://api.openweathermap.org/data/2.5/weather?q=$_city&appid=$openWeatherApiKey");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Extract timezone offset (in seconds)
          _timezoneOffset = data['timezone'];

          // Adjust local time for the queried city's timezone
          _cityLocalTime = d!.toUtc().add(Duration(seconds: _timezoneOffset));
          _citySunrise = s!.toUtc().add(Duration(seconds: _timezoneOffset));
          _citySunset = su!.toUtc().add(Duration(seconds: _timezoneOffset));

          // Update city after successful fetch
          _city = city;
          _error = null; // Ensure error is cleared if the fetch is successful
          _cityerror = null;
        } else {

          _error = "Failed to fetch timezone offset";
        }
      } catch (e) {
        final errorString = e.toString();

        try {
          final errorJson = json.decode(
            errorString.substring(errorString.indexOf('{')),
          );

          if (errorJson is Map<String, dynamic> && errorJson['message'] != null) {
            // print(errorJson['message']);
            if (errorJson['message'] == "city not found") {
              _cityerror = errorJson['message'];

            } else {
              _error = errorJson['message'];
              // print("error ${_error}");
            }
          } else {
            _error = "An unknown error occurred.";
          }
        } catch (_) {
          _error = errorString; // Fallback to raw error message
          // print(_error);
        }
      }
      notifyListeners();
    }
    else{
      return;
    }

  }

// ForeCast  function
  Future<void> fetchForecast() async {

    if(_isConnected){
      if (_city.isEmpty) return;

      final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?q=$_city&units=$_forecastunit&appid=$openWeatherApiKey");

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List forecasts = data['list'];

          // Keep all forecast data, regardless of the current local time
          _forecast = forecasts;

          // print("All forecast data: $_forecast");
          _error = null;
        } else {
          // print("Error response code: ${response.statusCode}");
          // _error = "Failed to fetch forecast data";
        }
      } catch (error) {
        // print("Error occurred: $error");
        // _error = "An error occurred: Try again";
      } finally {
        notifyListeners();
      }
    }
    else{
      return;
    }

  }

  List<Map<String, dynamic>> getThreeDayForecast() {
    if (_forecast == null) return [];

    final Map<String, List<Map<String, dynamic>>> groupedForecast = {};

    for (var item in _forecast!) {
      final date = item['dt_txt'].split(' ')[0]; // Extract date
      groupedForecast.putIfAbsent(date, () => []).add(item);
    }

    final List<Map<String, dynamic>> result = [];
    final today = _cityLocalTime;


    final normalizedToday =
    DateTime(today.year, today.month, today.day);
    int count = 0;

    for (var date in groupedForecast.keys) {
      final forecastDate = DateTime.parse(date);

      if (forecastDate.isBefore(normalizedToday)) {
        continue;
      }

      final dayForecast = groupedForecast[date]!;

      final highestTemp = dayForecast
          .map((item) => item['main']['temp'])
          .reduce((a, b) => a > b ? a : b);
      final lowestTemp = dayForecast
          .map((item) => item['main']['temp'])
          .reduce((a, b) => a < b ? a : b);

      final morning = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('09:00:00'),
        orElse: () => defaultMap,
      );
      final noon = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('12:00:00'),
        orElse: () => defaultMap,
      );

      final afternoon = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('15:00:00'),
        orElse: () => defaultMap,
      );

      final evening = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('18:00:00'),
        orElse: () => defaultMap,
      );
      final night = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('21:00:00'),
        orElse: () => defaultMap,
      );

      result.add({
        'date': date,
        'highest_temp': highestTemp,
        'lowest_temp': lowestTemp,
        'morning': morning,
        'noon': noon,
        'afternoon': afternoon,
        'evening': evening,
        'night': night,
      });

      count++;
      if (count >= 4) break;
    }

    return result;
  }

  final Map<String, dynamic> defaultMap = {
    'dt_txt': '0:0:0',
    'main': {
      'temp': 0.0,
      'humidity': 0.0,
    },
    'wind': {
      'speed': 0.0,
    },
    'weather': [
      {'description': 'Not'},
    ],
  };
// Toggle Unit and city function
  set setCity(String city){
    _city = city;
    notifyListeners();
  }

 void toggleUnit() async {
    if (_unit == "°") {
      // Switch to Fahrenheit
      _unit = "F";
      _forecastunit = "imperial";
    } else {
      // Switch to Celsius
      _unit = "°";
      _forecastunit = "metric";
    }

    notifyListeners();
  }

  //Error related helper functions
  set setErrorFromResponse(String response) {
    try {
      final parsedResponse = json.decode(response);
      if (parsedResponse['message'] != null) {
        _error = parsedResponse['message']; // Extract the 'message' field
      } else {
        _error = "An unknown error occurred.";
      }
    } catch (e) {
      _error = "Failed to parse error response.";
    }
    notifyListeners();
  }

  set setError(String? error) {
    _error = error;
    notifyListeners();
  }

// Shared Preference related Functions
  Future<void> fetchRecentSearches() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _recentSearches = prefs.getStringList('recentCities') ?? [];
    notifyListeners();
  }

  void setShowRecentSearches(bool value) {
    _showRecentSearches = value;
    notifyListeners();
  }

  void addCityToRecent(String city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Fetch the current list from SharedPreferences
    List<String> recentCities = prefs.getStringList('recentCities') ?? [];

    // Normalize cases for comparison
    String normalizedCity = city.toLowerCase();
    List<String> normalizedCities =
        recentCities.map((c) => c.toLowerCase()).toList();

    // If the city is already in the list, remove the old entry
    if (normalizedCities.contains(normalizedCity)) {
      int index = normalizedCities.indexOf(normalizedCity);
      recentCities.removeAt(index); // Remove the old city
    }

    // Add the city at the beginning (LIFO)
    recentCities.insert(0, city);

    // Save the updated list back to SharedPreferences
    prefs.setStringList('recentCities', recentCities);

    // Update the local list and notify listeners
    _recentSearches = recentCities;
    notifyListeners();
  }

  void removeCityFromRecent(String city) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(city);
    prefs.setStringList('recentCities', _recentSearches);
    notifyListeners();
  }

//  UI helper functions :
  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isConnected = connectivityResult != ConnectivityResult.none;
    // print("is: $_isConnected");
    notifyListeners();
  }
  bool _isNight() {
    final now = _cityLocalTime;
    final sunrise = _citySunrise;
    final sunset = _citySunset;

    if (now.isAfter(sunset) || now.isBefore(sunrise)) {
      return true;
    } else {
      return false;
    }
  }



  bool isExpanded(String key) {
    return _expandState[key] ?? false;
  }

  void toggleExpandState(String key) {
    _expandState[key] = !(_expandState[key] ?? false);
    notifyListeners();
  }

  double getTemp(double temp) {
// Access temperature based on the unit dynamically
    if (_unit == "°") {
      if (temp > -1 && temp < 1) {
        return 0;
      } else {
        return temp;
      }
    } else if (_unit == "F") {
      return ctf(temp);
    } else {
      return 0.0;
    }
  }

  String getWeatherType() {
    if (_weather == null || _weather!.weatherDescription == null) {
      return "default"; // Fallback if weather data isn't available
    }

    final description = _weather!.weatherDescription!.toLowerCase();
    if (description.contains('clear')) {
      return "clearSky";
    } else if (description.contains('cloud')) {
      return "cloudy";
    } else if (description.contains('rain')) {
      return "rainyOvercast";
    } else if (description.contains('snow')) {
      return "snowfall";
    } else if (description.contains('thunderstorm')) {
      return "thunderstorm";
    } else if (description.contains('mist')) {
      return "misty";
    } else if (description.contains('haze')) {
      return "haze";
    } else if (description.contains('fog')) {
      return "fog";
    }

    return "default"; // For unhandled weather types
  }





  final citiesByCountry = {
    'United States': [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'Phoenix',
      'Philadelphia',
      'San Antonio',
      'San Diego',
      'Dallas',
      'San Francisco'
    ],
    'India': [
      'Srinagar',
      'Mumbai',
      'Delhi',
      'Bengaluru',
      'Hyderabad',
      'Chennai',
      'Kolkata',
      'Pune',
      'Jaipur',
      'Ahmedabad',
      'Kochi'
    ],
    'Japan': [
      'Tokyo',
      'Osaka',
      'Kyoto',
      'Yokohama',
      'Nagoya',
      'Sapporo',
      'Fukuoka',
      'Hiroshima',
      'Sendai',
      'Kobe'
    ],
    'Germany': [
      'Berlin',
      'Munich',
      'Frankfurt',
      'Hamburg',
      'Cologne',
      'Stuttgart',
      'Düsseldorf',
      'Leipzig',
      'Dortmund',
      'Bremen'
    ],
    'France': [
      'Paris',
      'Marseille',
      'Lyon',
      'Toulouse',
      'Nice',
      'Nantes',
      'Strasbourg',
      'Montpellier',
      'Bordeaux',
      'Lille'
    ],
    'United Kingdom': [
      'London',
      'Manchester',
      'Birmingham',
      'Liverpool',
      'Edinburgh',
      'Glasgow',
      'Leeds',
      'Bristol',
      'Sheffield',
      'Nottingham'
    ],
    'Turkey': [
      'Istanbul',
      'Ankara',
      'Izmir',
      'Bursa',
      'Antalya',
      'Adana',
      'Gaziantep',
      'Konya',
      'Kayseri',
      'Mersin'
    ],
  };
  final List<String> countries = [
    'United States',
    'India',
    'Japan',
    'Germany',
    'France',
    'United Kingdom',
    'Turkey'
  ];




}
