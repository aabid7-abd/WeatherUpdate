import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:weather_animation/weather_animation.dart';

import 'Api.dart';
import 'StateManage.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> fetchWeatherData() async {
    try {
      String city = await getCityName();
      if (city == "" || city == "Ganderbal") {
        city = "Srinagar";
        Provider.of<WeatherProvider>(context, listen: false)
            .setCity("Srinagar");
      } else {}
      Provider.of<WeatherProvider>(context, listen: false).setCity(city);
      await Provider.of<WeatherProvider>(context, listen: false).fetchd();
      await Provider.of<WeatherProvider>(context, listen: false)
          .fetchForecast();
    } catch (e) {
      print("Error in fetchWeatherData: $e");
    }

    // Use listen: false to avoid listening for changes to the provider
  }

  @override
  void initState() {
    super.initState();
    // Call the async method to fetch weather data
    fetchWeatherData();
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);

    weatherProvider.fetchRecentSearches();
    weatherProvider.focusNode?.addListener(() {
      if (!weatherProvider.focusNode!.hasFocus) {
        weatherProvider.setShowRecentSearches(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weatherDescription =
        weatherProvider.weather?.weatherDescription?.toLowerCase() ?? "";
    return weatherProvider.weather == null && weatherProvider.forecast == null
        ? const Scaffold(
       body: Center(
     child : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 20),
          Text('Fetching....'),
        ],
      ),
    )):Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: weatherProvider.weather != null
          ? weatherProvider.getColorBasedOnWeather(weatherDescription)
          : Colors.white,
      body: _mainUI(),
      floatingActionButton: FloatingActionButton(
        onPressed: weatherProvider.toggleUnit,
        child: SizedBox(
          width: 40,
          height: 40,
          child: weatherProvider.unit == "F"
              ? Image.asset("assets/icons/celsius.png")
              : Image.asset("assets/icons/F.png"),
        ),
      ),
    );
  }

  Widget buildWeatherBackground(WeatherProvider weatherProvider) {
    return Positioned.fill(
      child: Builder(
        builder: (context) {
          final weatherType = weatherProvider.getWeatherType();

          // Map the weather type to the corresponding WeatherScene
          switch (weatherType) {
            case "clearSky":
              return const WrapperScene(
                colors: [
                  Color(0xff87ceeb),
                  Color(0xff4682b4),
                ],
                children: [
                  SunWidget(
                    sunConfig: SunConfig(
                      width: 262.0,
                      blurSigma: 20.0,
                      blurStyle: BlurStyle.solid,
                      isLeftLocation: true,
                      coreColor: Color(0xffffa726),
                      midColor: Color(0xd6ffee58),
                      outColor: Color(0xffff9800),
                      animMidMill: 2000,
                      animOutMill: 1800,
                    ),
                  ),
                ],
              );
            case "cloudy":
              return WrapperScene(
                colors: [
                  const Color(0xffd3d3d3),
                  const Color(0xffa9a9a9),
                ],
                children: [
                  SizedBox(
                    width: 950,
                    height: 470,
                    child: Transform.scale(
                      scale: 0.3,
                      child: const CloudWidget(),
                    ),
                  ),
                  const WindWidget(),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Transform.scale(
                      scale: 0.4,
                      child: const CloudWidget(),
                    ),
                  ),
                ],
              );
            case "rainyOvercast":
              return WeatherScene.rainyOvercast.sceneWidget;
            case "snowfall":
              return const WrapperScene(
                colors: [
                  Color(0xfff8f9fa),
                  Color(0xffd6d6d6),
                ],
                children: [
                  SnowWidget(),
                ],
              );
            case "thunderstorm":
              return WeatherScene.stormy.sceneWidget;
            case "misty":
              return const WrapperScene(
                colors: [
                  Color(0xffe0e0e0),
                  Color(0xffcfd8dc),
                ],
                children: [],
              );
            default:
              return const WrapperScene(
                colors: [
                  Color(0xff87ceeb),
                  Color(0xff4682b4),
                ],
                children: [],
              );
          }
        },
      ),
    );
  }

  Widget _mainUI() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    return
     weatherProvider.error != null
        ? Stack(
      children: [
        buildWeatherBackground(weatherProvider),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                width: MediaQuery.of(context).size.width * 0.5,
                child: Image.asset('assets/icons/error.png'),
              ),
            ),
            Text(
              weatherProvider
                  .capitalizeEachWord(weatherProvider.error!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Positioned(
          top: 60,
          left: 0,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: _search(),
          ),
        ),
        Positioned(
          top: 120,
          left: 40,
          right: 40,
          child: _searchbox(weatherProvider),
        ),
      ],
    )
        : Stack(
      children: [
        buildWeatherBackground(weatherProvider),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _search(),
              ),
              const SizedBox(height: 20),
              _upperHeader(),
              _currentInfo(),
            ],
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.26,
          left: MediaQuery.of(context).size.width * 0.43,
          right: 10,
          child: SizedBox(
            height: 400,
            child: _buildWeatherIconAndDescription(
                weatherProvider, false),
          ),
        ),
        // Center(
        //   child: ClipPath(
        //     clipper: WavyClipper(),
        //     child: Container(
        //       height: 300,
        //       width: 300,
        //       color: Colors.blue,
        //     ),
        //   ),
        // ),
        Positioned(
          bottom: 0, // Anchors it to the bottom
          left: 0,
          right: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.4, // Limits height
            ),

            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _threeDayForecast(),
            ),
          ),
        ),
        Positioned(
          top: 120, // Anchors it to the bottom
          left: 40,
          right: 35,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.4, // Limits height
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(40),
                topLeft: Radius.circular(40),
              ),
              color: Colors.white.withOpacity(0.8),
            ),
            child: _searchbox(weatherProvider),
          ),
        ),
      ],
    );
  }

  void showCountriesDialog(BuildContext context) {
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Country'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: weatherProvider.countries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(weatherProvider.countries[index]),
                  onTap: () {
                    final selectedCountry = weatherProvider.countries[index];
                    Navigator.of(context).pop(); // Close the countries dialog
                    showCitiesDialog(context, selectedCountry); // Show cities
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showCitiesDialog(BuildContext context, String country) {
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);

    // Mapping of countries to their cities

    final cities = weatherProvider.citiesByCountry[country] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a City in $country'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cities[index]),
                  onTap: () {
                    final selectedCity = cities[index];
                    _searchController.text = selectedCity;
                    weatherProvider.setCity(selectedCity);
                    weatherProvider.fetchd();
                    weatherProvider.fetchForecast();
                    weatherProvider.addCityToRecent(selectedCity);

                    print('Selected City: $selectedCity');
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }



  Widget _searchbox(WeatherProvider weatherProvider) {
    if (weatherProvider.showRecentSearches &&
        weatherProvider.recentSearches.isNotEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 10),
              child: buildText('Recent '),
            ),
            SizedBox(
              height: 150,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: weatherProvider.recentSearches.length,
                itemBuilder: (context, index) {
                  final city = weatherProvider.recentSearches[index];
                  return ListTile(
                    title: InkWell(
                        onTap: () {
                          _searchController.text = city;
                          weatherProvider.setCity(city);
                          weatherProvider.addCityToRecent(city);
                          weatherProvider.fetchd();
                          weatherProvider.fetchForecast();
                          weatherProvider.setShowRecentSearches(false);
                        },
                        child: Text(city)),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.black),
                      onPressed: () {
                        weatherProvider.removeCityFromRecent(city);
                      },
                    ),
                  );
                },
              ),
            ),
            if (weatherProvider.recentSearches.length > 2)...[
              const Divider(), // Optional separator
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Scroll to see more',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
            ]

          ],
        ),
      );
    }
    return const SizedBox
        .shrink(); // Return an empty widget if no recent searches
  }

  Widget _search() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: weatherProvider.focusNode,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                prefixIcon: IconButton(
                  onPressed: () => showCountriesDialog(context),
                  icon: const Icon(
                    Icons.location_city,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 50, // Set minimum width for spacing
                ),
                contentPadding:
                    const EdgeInsets.only(left: 10), // Add left padding
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final city = _searchController.text;
                    if (city.isNotEmpty) {
                      weatherProvider.setCity(city);
                      weatherProvider.fetchd();
                      weatherProvider.fetchForecast();
                      weatherProvider.addCityToRecent(city);
                      weatherProvider.setShowRecentSearches(false);
                    }
                  },
                ),
              ),
              onTap: () {
                weatherProvider.setShowRecentSearches(true);
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _threeDayForecast() {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return ListView.builder(
      itemCount: weatherProvider.getThreeDayForecast().length,
      itemBuilder: (context, index) {
        final forecastDay = weatherProvider.getThreeDayForecast()[index];
        double? windSpeedM = double.tryParse(
            forecastDay['morning']['wind']['speed']?.toString() ?? '');
        double? windSpeedA = double.tryParse(
            forecastDay['afternoon']['wind']['speed']?.toString() ?? '');
        double? windSpeedE = double.tryParse(
            forecastDay['evening']['wind']['speed']?.toString() ?? '');

        return
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: index ==0 ?Colors.grey.shade50: index ==1?Colors.grey.shade100:Colors.grey.shade200,

            ),
            margin: const EdgeInsets.only(bottom: 40),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      index == 0
                          ? Text(
                              'Tomorrow${DateFormat(" d MMM ").format(DateTime.parse(forecastDay['date']))}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            )
                          : Text(
                              "${DateFormat('EEEE ').format(DateTime.parse(forecastDay['date']))}${DateFormat('d MMM ').format(DateTime.parse(forecastDay['date']))}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ],
                  ),
                  Card(

                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          buildText(
                              '${forecastDay['highest_temp'].toInt()} ${weatherProvider.unit}'),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.arrow_upward,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          buildText(
                              '${forecastDay['lowest_temp'].toInt()} ${weatherProvider.unit}'),
                          const Icon(
                            Icons.arrow_downward,
                            size: 14,
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildWeatherSection(index, "Morning", forecastDay['morning'],
                    windSpeedM, weatherProvider.unit, weatherProvider, forecastDay),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildWeatherSection(index, "Afternoon", forecastDay['afternoon'],
                    windSpeedA, weatherProvider.unit, weatherProvider, forecastDay),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildWeatherSection(index, "Evening", forecastDay['evening'],
                    windSpeedE, weatherProvider.unit, weatherProvider, forecastDay),
              ),

            ],
                    ),
          );
      },
    );
  }

// Helper function to create weather sections (Morning, Afternoon, Evening)
  Widget _buildWeatherSection(
    int index,
    String timeOfDay,
    dynamic forecast,
    double? windSpeed,
    String unit,
    WeatherProvider weather,
    Map<String, dynamic> forecastDay,
  ) {
    final sectionKey = '$index-$timeOfDay';

    return SizedBox(
      width: MediaQuery.of(context).size.width * 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  Text(
                    timeOfDay,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.withOpacity(0.9),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      print(sectionKey);
                      weather.toggleExpandState(sectionKey);
                    },
                    icon: Icon(weather.isExpanded(sectionKey)
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down),
                  ),
                ],
              ),
              // Weather description and icon
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    forecast['weather'][0]['description'] != "clear sky"
                        ? Image.network(
                            'https://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}@4x.png',
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset('assets/icons/bad.png',
                                  width: 50, height: 50);
                            },
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/icons/sun.png'),
                              ),
                            ),
                          ),
                    buildText(weather.capitalizeEachWord(
                        '${forecast['weather'][0]['description']}')),
                  ],
                ),
              ),
            ],
          ),

          weather.isExpanded(sectionKey)
              ? Card(
                  elevation: 5,
                  child: Container(
                    decoration: BoxDecoration(
                        color: weather
                            .getColorBasedOnWeather(
                                weather.weather?.weatherDescription ?? "")
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 90,
                              child: Column(
                                children: [
                                  buildText(
                                      '${forecast['main']['temp'].toInt()} $unit'),
                                  buildText('Temperature'),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 90,
                              child: Column(
                                children: [
                                  buildText(
                                      '${forecast['main']['humidity']} %,'),
                                  buildText('Humidity'),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: _buildWeatherInfoColumn(
                                value: getWindSpeed(windSpeed, context),
                                label: getWindSpeedDescription(windSpeed),
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  Widget buildText(String input) {
    return Text(
      input,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }

  Widget _upperHeader() {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    DateTime now = weatherProvider.weather!.date!;

    return Padding(
      padding: const EdgeInsets.only(left: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_pin,
                color: Colors.white,
                size: 27,
              ),
              Text(
                '${weatherProvider.weather?.areaName}, ' ?? "",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                weatherProvider.weather?.country ?? "",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25.0),
            child: Row(
              children: [
                Text(
                    'Today, ${DateFormat("d MMM y").format(now)}, ${DateFormat("h:mm a").format(now)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentInfo() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    double temperature = weatherProvider.getTemp();
    final weatherDescription =
        weatherProvider.weather?.weatherDescription?.toLowerCase() ?? "";
    bool isNight = _isNight(weatherProvider);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25.0),
                  child: _buildTemperatureRow(weatherProvider, temperature),
                ),
              ],
            ),
          ),
          _buildMaxMinTempCard(weatherProvider, weatherDescription),
          _extraCurrentInfo(),
          const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  bool _isNight(WeatherProvider weatherProvider) {
    if (weatherProvider.weather?.sunset != null &&
        weatherProvider.weather?.sunrise != null) {
      final localSunrise = weatherProvider.weather!.sunrise!.toLocal();
      final localSunset = weatherProvider.weather!.sunset!.toLocal();
      final now = DateTime.now();
      return now.isAfter(localSunset) || now.isBefore(localSunrise);
    }
    return false;
  }

  Widget _buildTemperatureRow(
      WeatherProvider weatherProvider, double temperature) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          temperature.toStringAsFixed(0),
          style: const TextStyle(color: Colors.white, fontSize: 120),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: Text(
            weatherProvider.unit,
            style: const TextStyle(color: Colors.white, fontSize: 30),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherIcon(WeatherProvider weatherProvider) {
    final weatherDescription =
        weatherProvider.weather?.weatherDescription?.toLowerCase() ?? "";
    if (weatherDescription == "clear sky") {
      return Padding(
        padding: const EdgeInsets.only(top: 35.0),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/icons/sun.png'),
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 35.0),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://openweathermap.org/img/wn/${weatherProvider.weather?.weatherIcon}@4x.png',
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildWeatherIconAndDescription(
      WeatherProvider weatherProvider, bool isNight) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 30),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildWeatherIcon(weatherProvider),
            const SizedBox(width: 10),
            Text(
              weatherProvider.weather?.weatherDescription != null
                  ? weatherProvider.capitalizeEachWord(
                      weatherProvider.weather!.weatherDescription!)
                  : 'No description available',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxMinTempCard(
      WeatherProvider weatherProvider, String weatherDescription) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: weatherProvider
                  .getColorBasedOnWeather(weatherDescription)
                  .withOpacity(0.2),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            height: MediaQuery.of(context).size.height * 0.05,
            width: MediaQuery.of(context).size.width * 0.5,
            child: weatherProvider.tunit == "celsius"
                ? _buildTemperatureRowWithUnit(
                    temperatureMax: weatherProvider.weather?.tempMax?.celsius,
                    temperatureMin: weatherProvider.weather?.tempMin?.celsius,
                    unit: weatherProvider.unit,
                  )
                : _buildTemperatureRowWithUnit(
                    temperatureMax:
                        weatherProvider.weather?.tempMax?.fahrenheit,
                    temperatureMin:
                        weatherProvider.weather?.tempMin?.fahrenheit,
                    unit: weatherProvider.unit,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemperatureRowWithUnit(
      {double? temperatureMax, double? temperatureMin, required String unit}) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weatherDescription =
        weatherProvider.weather?.weatherDescription?.toLowerCase() ?? "";

    return Card(
      elevation: 6,
      color: weatherProvider
          .getColorBasedOnWeather(weatherDescription)
          .withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${temperatureMax?.toStringAsFixed(0)} $unit',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.arrow_upward, color: Colors.white, size: 15),
          const SizedBox(width: 20),
          Text(
            '${temperatureMin?.toStringAsFixed(0)} $unit',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const Icon(Icons.arrow_downward, size: 15, color: Colors.white)
        ],
      ),
    );
  }

  Widget _extraCurrentInfo() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weatherDescription =
        weatherProvider.weather?.weatherDescription?.toLowerCase() ?? "";

    return Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        height: MediaQuery.of(context).size.height * 0.09,
        width: double.maxFinite,
        child: Card(
          elevation: 5,
          color: weatherProvider
              .getColorBasedOnWeather(weatherDescription)
              .withOpacity(0.6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherInfoColumn(
                value:
                    '${weatherProvider.weather?.humidity?.toStringAsFixed(0)} %',
                label: 'Humidity',
              ),
              _buildWeatherInfoColumn(
                value:
                    getWindSpeed(weatherProvider.weather?.windSpeed, context),
                label:
                    getWindSpeedDescription(weatherProvider.weather?.windSpeed),
                fontSize: 16,
              ),
              _buildWeatherInfoColumn(
                value: '${weatherProvider.weather?.pressure} ',
                label: 'Pressure',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfoColumn({
    required String value,
    required String label,
    Color color = Colors.white,
    double fontSize = 14,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: fontSize),
        ),
        Text(
          label,
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  String getWindSpeed(double? windSpeed, BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    String u = weatherProvider.tunit; // "celsius" or "fahrenheit"

    if (windSpeed == null) return 'N/A';

    if (u == "celsius") {
      return '${windSpeed.toStringAsFixed(1)} m/s'; // For metric (m/s)
    } else if (u == "fahrenheit") {
      return '${(windSpeed * 2.237).toStringAsFixed(1)} mph'; // For imperial (mph)
    } else {
      return 'N/A';
    }
  }

  String getWindSpeedDescription(double? windSpeed) {
    if (windSpeed == null) return 'N/A';

    // Wind speed description based on m/s or mph, but not considering units for description
    if (windSpeed < 0.3) return 'Calm';
    if (windSpeed < 1.5) return 'Light Air';
    if (windSpeed < 3.3) return 'Light Breeze';
    if (windSpeed < 5.5) return 'Gentle Breeze';
    if (windSpeed < 7.9) return 'Moderate Breeze';
    if (windSpeed < 10.7) return 'Fresh Breeze';
    if (windSpeed < 13.8) return 'Strong Breeze';
    if (windSpeed < 17.1) return 'High Wind';
    return 'Gale or Stronger';
  }
}
// class WavyClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     var path = new Path();
//     path.lineTo(0, size.height / 8);
//     var firstControlPoint = new Offset(size.width / 4, size.height/4);
//     var firstEndPoint = new Offset(size.width / 2, size.height / 4 - 60);
//     var secondControlPoint =
//     new Offset(size.width - (size.width / 4), size.height / 5 - 92);
//     var secondEndPoint = new Offset(size.width, size.height / 4);
//     // var thirdcp =
//     // new Offset(size.width - (size.width / 4), size.height / 4 - 65);
//     // var thirdep = new Offset(size.width, size.height / 3 - 40);
//
//     path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
//         firstEndPoint.dx, firstEndPoint.dy);
//     path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
//         secondEndPoint.dx, secondEndPoint.dy);
//     // path.quadraticBezierTo(thirdcp.dx, thirdep.dy,
//     //     thirdcp.dx, thirdep.dy);
//
//     // path.lineTo(size.width, 0);
//     // path.lineTo(size.width, size.height/3.56);
//     path.lineTo(size.width, size.height); // botom right
//     path.lineTo(0, size.height); // botom left
//     path.close();
//     return path;
//   }
//
//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) {
//     return false;
//   }
// }