import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather/weather.dart';

import 'Api.dart';

class WeatherProvider with ChangeNotifier {
  String _city = "";
 DateTime? _cityLocalTime;
 DateTime? _citySunrise;
   DateTime? _citySunset;
  String _unit = "°";
  String _forecastunit = "metric";
  Weather? _weather;
  String? _error;
  bool isExpand = false;
  bool dayExpand = true;
  final WeatherFactory wf = WeatherFactory(openWeatherApiKey);
  Map<String, dynamic>? _error2;
  final FocusNode _focusNode = FocusNode();
  List<dynamic>? _forecast;

  final Map<String, bool> _expandState = {};

  Weather? get weather => _weather;
  List? get forecast => _forecast;
  DateTime? get cityLocalTime => _cityLocalTime;
  DateTime? get citySunrise => _citySunrise;
  DateTime? get citySunset => _citySunset;

  String get city => _city;
  String get unit => _unit;
  String get forecastunit => _forecastunit;
  String? get error => _error;
  Map<String, dynamic>? get error2 => _error2;

  List<String> _recentSearches = [];
  bool _showRecentSearches = false;
  bool get showRecentSearches => _showRecentSearches;
  bool get isNight => _isNight();
  List<String> get recentSearches => _recentSearches;
  FocusNode? get focusNode => _focusNode;
  Future<void> fetchd() async {
    try {
      // Fetch weather data
      _weather = await wf.currentWeatherByCityName(_city);
      DateTime? d = _weather?.date;
      DateTime? s = _weather?.sunrise;
      DateTime? su = _weather?.sunset;

      // print('city: $_city ${_weather?.country}');
      // print('lat ${_weather?.latitude}');
      // print('long ${_weather?.longitude}');

      // Fetch timezone offset from OpenWeather API
      final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/weather?q=$_city&appid=$openWeatherApiKey");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract timezone offset (in seconds)
        int timezoneOffset = data['timezone'];

        // print('Timezone offset: $timezoneOffset');

        // Adjust local time for the queried city's timezone
       _cityLocalTime = d!.toUtc().add(Duration(seconds: timezoneOffset));
       _citySunrise = s!.toUtc().add(Duration(seconds: timezoneOffset));
      _citySunset = su!.toUtc().add(Duration(seconds: timezoneOffset));

        // print('Local time in city: ${DateFormat("h:mm a").format(_cityLocalTime!)}');
        // print('sunrise: ${DateFormat("h:mm a").format(_citySunrise!)}');
        // print('sunset: ${DateFormat("h:mm a").format(_citySunset!)}');
      } else {
        print('Failed to fetch timezone offset');
      }

      _city = city;
      _error = null; // Ensure error is cleared if the fetch is successful

      notifyListeners();
    } catch (e) {
      final errorString = e.toString();

      try {
        final errorJson = json.decode(
          errorString.substring(errorString.indexOf('{')),
        );

        if (errorJson is Map<String, dynamic> && errorJson['message'] != null) {
          _error = errorJson['message'];
        } else {
          _error = "An unknown error occurred.";
        }
      } catch (_) {
        _error = errorString; // Fallback to raw error message
      }

      notifyListeners();
    }
  }

  bool _isNight() {

    final now = _cityLocalTime; // Current time in the city
    final sunrise = _citySunrise!;
    final sunset = _citySunset!;
    // print(now);
    if(now!.isAfter(sunset)&& now.isBefore(sunrise)) {
      return  true;
    }
    else {
      return false;
    }
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

  double ftc(double fahrenheit) {
    return (fahrenheit - 32) * 5 / 9;
  }

  double ctf(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  Future<void> toggleUnit() async {


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



  List<Map<String, dynamic>> getThreeDayForecast() {
    if (_forecast == null) return [];

    final Map<String, List<Map<String, dynamic>>> groupedForecast = {};

    for (var item in _forecast!) {
      final date = item['dt_txt'].split(' ')[0]; // Extract date
      groupedForecast.putIfAbsent(date, () => []).add(item);
    }

    final List<Map<String, dynamic>> result = [];
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day); // Normalize to 00:00
    int count = 1;

    for (var date in groupedForecast.keys) {
      final forecastDate = DateTime.parse(date);

      if (forecastDate.isBefore(today)) {
        continue;
      }
      if(count >3)break;


      final dayForecast = groupedForecast[date]!;

      // Find the highest and lowest temperature of the day
      final highestTemp = dayForecast
          .map((item) => item['main']['temp'])
          .reduce((a, b) => a > b ? a : b);

      final lowestTemp = dayForecast
          .map((item) => item['main']['temp'])
          .reduce((a, b) => a < b ? a : b);

      final morning = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('09:00:00'),
        orElse: () => {
          'dt_txt': 'N/A',
          'main': {'temp': 'N/A', 'humidity': 'N/A'},
          'wind': {'speed': 'N/A'},

          'weather': [{'description': 'Not available'}],
        },
      );

      final afternoon = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('12:00:00'),
        orElse: () => {
          'dt_txt': 'N/A',
          'main': {'temp': 'N/A', 'humidity': 'N/A'},
          'wind': {'speed': 'N/A'},
          'weather': [{'description': 'Not available'}],
        },
      );

      final evening = dayForecast.firstWhere(
            (item) => item['dt_txt'].contains('18:00:00'),
        orElse: () => {
          'dt_txt': 'N/A',
          'main': {'temp': 'N/A', 'humidity': 'N/A'},
          'wind': {'speed': 'N/A'},
          'weather': [{'description': 'Not available'}],
        },
      );

      result.add({
        'date': date,
        'highest_temp': highestTemp,
        'lowest_temp': lowestTemp,
        'morning': morning,
        'afternoon': afternoon,
        'evening': evening,
      });

      count++;
    }
    return result;
  }


  bool isExpanded(String key) {
    return _expandState[key] ?? false;
  }

  void toggleExpandState(String key) {
    _expandState[key] = !(_expandState[key] ?? false);
    notifyListeners();
  }








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
    List<String> normalizedCities = recentCities.map((c) => c.toLowerCase()).toList();

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







  void setErrorFromResponse(String response) {
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





double getTemp(double temp){
// Access temperature based on the unit dynamically
  if (_unit ==  "°") {
    if(temp >-1 && temp<1){ return 0;}
    else{ return temp;}

  } else if (_unit == "F") {
    return  ctf(temp);
  }
  else {
      return 0.0;
    }
  }




  void setError(String? error) {

    _error = error;
    notifyListeners();
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
    } else if (description.contains('rainy')) {
      return "rainyOvercast";

    } else if (description.contains('snow')) {
      return "snowfall";
    } else if (description.contains('thunderstorm')) {
      return "thunderstorm";
    } else if (description.contains('mist')) {
      return "misty";}
    else if (description.contains('haze')) {
      return "haze";
    } else if (description.contains('fog')) {
      return "fog";
    }

    return "default"; // For unhandled weather types
  }


  Color getColorBasedOnWeather(String description) {
      switch (description.toLowerCase()) {
        case 'clear sky':
          return  const Color(0xff87ceeb)
    ; // For clear sky (sunny weather)
        case 'few clouds':
        case 'scattered clouds':
        case 'broken clouds':
        case 'overcast clouds':
          return  const Color(0xffd3d3d3); // For cloudy weather
        case 'rain':
        case 'light rain':
        case 'moderate rain':
          return Colors.blueGrey; // For rainy weather
        case 'snow':
          return Colors.grey.shade50; // For snowy weather
        case 'light snow':
          return Colors.grey.shade50;
        case 'thunderstorm':
          return Colors.indigo; // For thunderstorm
        case 'mist':
          return Colors.grey.shade400;

      case 'haze':
      return Colors.grey.shade500;
        default:
          return Colors
              .blue; // For default (e.g., if the description is not recognized)
      }
    }

  void setCity(String city) async {
    _city = city;
    notifyListeners();
  }


  Future<void> fetchForecast() async {
    if (_city.isEmpty) return;


      final url = Uri.parse(
          "https://api.openweathermap.org/data/2.5/forecast?q=$_city&units=$_forecastunit&appid=$openWeatherApiKey");
      try {

        final response = await http.get(url);
        if (response.statusCode == 200) {
          _forecast = json.decode(response.body)['list'];
          _error = null;

        } else {

        }
      } catch (error) {
        _error = "An error occurred: Try again";
      } finally {
        notifyListeners();
      }




  }







  String capitalizeEachWord(String input) {
    if (input.isEmpty) return input;

    return input
        .split(' ')
        .map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() +
          word.substring(1);
    }).join(' ');
  }


}
