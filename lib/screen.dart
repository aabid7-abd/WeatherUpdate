import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:forecast/utility.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'Api.dart';
import 'StateManage.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> fetchWeatherData() async {
    try {
      WeatherProvider weather =
          Provider.of<WeatherProvider>(context, listen: false);

      String city = await getCityName();
      if (city=="default" || city == "Ganderbal") {
        weather.setCity = "Srinagar";

      } else {
        weather.setCity = city;

      }
      await weather.fetchd();
      await weather.fetchForecast();

    } catch (e) {



      // print("Error in fetchWeatherData: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);

    weatherProvider.checkConnectivity();

    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      weatherProvider.isconnected = result != ConnectivityResult.none;

      if (weatherProvider.isConnected) {
        await fetchWeatherData();
      } else {
        // print("No internet connection detected.");
      }
    });

    weatherProvider.fetchRecentSearches();
    weatherProvider.focusNode?.addListener(() {
      if (!weatherProvider.focusNode!.hasFocus) {
        weatherProvider.setShowRecentSearches(false);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription
        ?.cancel(); // Cancel subscription to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return


      weatherProvider.weather == null && weatherProvider.forecast == null
        ? Scaffold(
            backgroundColor: Colors.blueGrey,
            body:
            buildErrorUI(
              'Oh no! It seems I’m having trouble checking the weather.\n'
                  'Could you please check your connection while I try again?',
              context,
            )
      )
        : weatherProvider.cityerror != null
            ? Scaffold(
                body: Stack(
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
                          capitalizeEachWord(weatherProvider.cityerror!),
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
                ),
              )
            : Scaffold(
                resizeToAvoidBottomInset: false, // Prevent resizing
                extendBodyBehindAppBar: true,
                body: _mainUI(),
                floatingActionButton: FloatingActionButton(
                  onPressed: weatherProvider.toggleUnit,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.white,
                  focusColor: Colors.grey,
                  hoverColor: Colors.lightBlue,
                  splashColor: Colors.grey.shade200,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: weatherProvider.unit == "F"
                        ? Image.asset("assets/icons/celsius.png")
                        : Image.asset("assets/icons/F.png"),
                  ),
                ));
  }

  Widget _mainUI() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    double tempfeelslike = weatherProvider
        .getTemp(weatherProvider.weather?.tempFeelsLike?.celsius ?? 0.0);

    return Stack(
      children: [
        weatherProvider.weather?.weatherDescription == 'clear sky'
            ? weatherProvider.isNight
                ? Positioned.fill(
                    child: Lottie.asset(
                      'assets/lottie/lo.json',
                      fit: BoxFit.cover, // Cover the entire background
                    ),
                  )
                : Positioned.fill(
                    child: Lottie.asset(
                      'assets/lottie/clearday.json',
                      fit: BoxFit.cover, // Cover the entire background
                    ),
                  )
            : buildWeatherBackground(weatherProvider),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _upperHeader(),
                    const Padding(
                      padding: EdgeInsets.only(left: 10.0, top: 10),
                      child: Text(
                        'Now',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    _currentInfo(),
                    Card(
                        elevation: 22,
                        color: getColorBasedOnWeather(
                                weatherProvider.weather?.weatherDescription ??
                                    " ")
                            .withOpacity(0.6),
                        child: _extraCurrentInfo()),
                      Padding(
                       padding: const EdgeInsets.only(top: 12.0),
                       child: Text('5 day Forecast',style: TextStyle(fontWeight: FontWeight.w800,fontSize: 17,color:
                       weatherProvider.isNight?Colors.white:Colors.white)

                         ,
                       ),
                     )
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 220,
          right: 20,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weatherProvider.weather?.weatherDescription != null
                          ? capitalizeEachWord(
                              weatherProvider.weather!.weatherDescription!)
                          : 'No description available',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Feels like ${tempfeelslike.toStringAsFixed(0)} ${weatherProvider.unit}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    sun(
                        'r',
                        DateFormat("h:mm a").format(
                            weatherProvider.citySunrise ?? DateTime.now()),
                        'assets/icons/sr2.png',
                        context),
                    const SizedBox(
                      height: 5,
                    ),
                    sun(
                        's',
                        DateFormat("h:mm a").format(
                            weatherProvider.citySunset ?? DateTime.now()),
                        'assets/icons/sunset-2.png',
                        context)
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _threeDayForecast(),
            ),
          ),
        ),
        Positioned(
          top: 120,
          left: 40,
          right: 35,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
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

  //current weather section
  Widget _upperHeader() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    DateTime now = weatherProvider.cityLocalTime!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(
                Icons.location_pin,
                color: Colors.white,
                size: 27,
              ),
              Text(
                '${weatherProvider.weather?.areaName},',
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
        ),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Text(
                '       ${DateFormat('EEEE ').format(now)}${DateFormat("d MMM y").format(now)}, ${DateFormat("h:mm a").format(now)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _currentInfo() {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    double temperature = weatherProvider
        .getTemp(weatherProvider.weather?.temperature?.celsius ?? 0.0);

    return Row(
      children: [
        Text(
          temperature.toStringAsFixed(0),
          style: TextStyle(
              color: weatherProvider.isNight &&
                      weatherProvider.weather?.weatherDescription == "clear sky"
                  ? const Color(0xff0f2027)
                  : Colors.white,
              fontSize: 100,
              fontWeight: FontWeight.w700),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 65.0),
          child: Text(
            weatherProvider.unit,
            style: const TextStyle(color: Colors.white, fontSize: 40),
          ),
        ),
        weatherProvider.isNight &&
                weatherProvider.weather?.weatherDescription == "clear sky"
            ? const SizedBox()
            : buildWeatherIcon(weatherProvider),
      ],
    );
  }

  Widget _extraCurrentInfo() {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      width: double.maxFinite,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildWeatherInfoColumn(
                value:
                    '${weatherProvider.weather?.humidity?.toStringAsFixed(0)} %',
                label: getHumidityLevelDescription(
                    weatherProvider.weather!.humidity!.toDouble()),
                path: 'assets/icons/humi.png'),
            buildWeatherInfoColumn(
                value:
                    getWindSpeed(weatherProvider.weather?.windSpeed, context),
                label:
                    getWindSpeedDescription(weatherProvider.weather?.windSpeed),
                fontSize: 16,
                path: 'assets/icons/wind.png'),
            buildWeatherInfoColumn(
                value:
                    '${weatherProvider.weather?.pressure?.toStringAsFixed(0)} hPa ',
                label:
                    getPressureLevel(weatherProvider.weather!.pressure ?? 0.0),
                path: 'assets/icons/pres.png'),
          ],
        ),
      ),
    );
  }

  //forecast section
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

        double? windSpeedNoon = double.tryParse(
            forecastDay['noon']['wind']['speed']?.toString() ?? '');
        double? windSpeednight = double.tryParse(
            forecastDay['night']['wind']['speed']?.toString() ?? '');

        // Safely parse temperatures and convert to double
        double highestTemp = forecastDay['highest_temp']?.toDouble() ?? 0.0;
        double lowestTemp = forecastDay['lowest_temp']?.toDouble() ?? 0.0;

        double conhightemp = weatherProvider.getTemp(highestTemp);
        double conLowtemp = weatherProvider.getTemp(lowestTemp);

        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => forecast(
                context,
                index,
                forecastDay,
                windSpeedM,
                windSpeedNoon,
                windSpeedA,
                windSpeedE,
                windSpeednight,
              ),
              backgroundColor: getColorBasedOnWeather(
                      weatherProvider.weather?.weatherDescription ?? " ")
                  .withOpacity(0.8),
              elevation: 8.0, // Elevation of the bottom sheet
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20), // Rounded top corners
                ),
              ),
              clipBehavior: Clip.antiAlias,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),

              isScrollControlled:
                  true, // Allow the bottom sheet to expand beyond default height
              isDismissible: true, // Allow dismissing by tapping outside
              enableDrag: true, // Allow dragging the sheet to dismiss
              showDragHandle: true, // Show a drag handle on top of the sheet
              useSafeArea: true, // Avoid system UI overlaps
              // routeSettings: RouteSettings(name: 'ForecastSheet'), // Custom route settings
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey.shade200,
            ),
            margin: const EdgeInsets.only(bottom: 40),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${DateFormat('EEEE ').format(DateTime.parse(forecastDay['date']))}${DateFormat('d MMM ').format(DateTime.parse(forecastDay['date']))}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Card(
                      elevation: 12,
                      color: getColorBasedOnWeather(
                              weatherProvider.weather!.weatherDescription ?? "")
                          .withOpacity(0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            buildText(
                                input:
                                    '${conhightemp.ceil()} ${weatherProvider.unit}'),
                            const SizedBox(width: 5),
                            buildText(input: '/'),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_upward,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            buildText(
                                input:
                                    '${conLowtemp.ceil()} ${weatherProvider.unit}'),
                            const Icon(
                              Icons.arrow_downward,
                              size: 14,
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget forecast(
    BuildContext context,
    index,
    forecastDay,
    windSpeedM,
    windSpeedNoon,
    windSpeedA,
    windSpeedE,
    windSpeednight,
  ) {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
        backgroundColor: Colors.grey.shade300,
        resizeToAvoidBottomInset: false, // Prevent resizing
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "${DateFormat('EEEE ').format(DateTime.parse(forecastDay['date']))}${DateFormat('d MMM ').format(DateTime.parse(forecastDay['date']))}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),

                _buildWeatherForecastSection(
                  index!,
                  "Morning",
                  forecastDay['morning'],
                  windSpeedM,
                  weatherProvider.unit,
                  weatherProvider,
                ),
                _buildWeatherForecastSection(
                  index,
                  "Noon",
                  forecastDay['noon'],
                  windSpeedNoon,
                  weatherProvider.unit,
                  weatherProvider,
                ),
                _buildWeatherForecastSection(
                  index,
                  "Afternoon",
                  forecastDay['afternoon'],
                  windSpeedA,
                  weatherProvider.unit,
                  weatherProvider,
                ),
                _buildWeatherForecastSection(
                  index,
                  "Evening",
                  forecastDay['evening'],
                  windSpeedE,
                  weatherProvider.unit,
                  weatherProvider,
                ),
                _buildWeatherForecastSection(
                  index,
                  "Night",
                  forecastDay['night'],
                  windSpeednight,
                  weatherProvider.unit,
                  weatherProvider,
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: weatherProvider.toggleUnit,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          focusColor: Colors.grey,
          hoverColor: Colors.lightBlue,
          splashColor: Colors.grey.shade200,
          child: SizedBox(
            width: 40,
            height: 40,
            child: weatherProvider.unit == "F"
                ? Image.asset("assets/icons/celsius.png")
                : Image.asset("assets/icons/F.png"),
          ),
        ));
  }

  Widget _buildWeatherForecastSection(
    int index,
    String time,
    dynamic forecast,
    double? windSpeed,
    String unit,
    WeatherProvider weather,
  ) {
    final sectionKey = '$index-$time';

    double temp = forecast['main']['temp']?.toDouble() ?? 0.0;
    double convertedTemp = weather.getTemp(temp);
    double humid = forecast['main']['humidity']?.toDouble() ?? 0.0;
    double pres = forecast['main']['sea_level']?.toDouble() ?? 0.0;
    String weatherDescription =
        forecast['weather'][0]['description'] ?? "Not";

    return SizedBox(
      width: MediaQuery.of(context).size.width * 1,
      child: weatherDescription == "Not"
          ? const SizedBox(
              height: 2,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            weather.toggleExpandState(sectionKey);
                          },
                          icon: Icon(weather.isExpanded(sectionKey)
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        weatherDescription != "clear sky"
                            ? Image.network(
                                'https://openweathermap.org/img/wn/${forecast['weather'][0]['icon']}@4x.png',
                                width: 50,
                                height: 50,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset('assets/icons/bad.png',
                                      width: 50, height: 50);
                                },
                              )
                            :(time == 'Evening' || time == 'Night')?  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image:
                                            AssetImage('assets/icons/moon.png'),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image:
                                            AssetImage('assets/icons/sun.png'),
                                      ),
                                    ),
                                  ),
                        const SizedBox(
                          height: 10,
                        ),
                        buildText(
                            input: capitalizeEachWord(weatherDescription)),
                      ],
                    ),
                    buildWeatherInfoColumn(
                      value: '${convertedTemp.toInt()} $unit',
                      label: 'Temperature',
                      fontSize: 16,
                      color: Colors.black,
                      path: 'assets/icons/temp.png',
                    ),
                  ],
                ),
                weather.isExpanded(sectionKey)
                    ? Card(
                        elevation: 12,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            color: getColorBasedOnWeather(
                                    weather.weather?.weatherDescription ?? "")
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                buildWeatherInfoColumn(
                                  value: '${forecast['main']['humidity']} %',
                                  label: getHumidityLevelDescription(humid),
                                  fontSize: 16,
                                  color: Colors.black,
                                  path: 'assets/icons/humi.png',
                                ),
                                buildWeatherInfoColumn(
                                  value: getWindSpeed(windSpeed, context),
                                  label: getWindSpeedDescription(windSpeed),
                                  fontSize: 16,
                                  color: Colors.black,
                                  path: 'assets/icons/wind.png',
                                ),
                                buildWeatherInfoColumn(
                                  value: '${forecast['main']['sea_level']} hPa',
                                  label: getPressureLevel(pres),
                                  fontSize: 16,
                                  color: Colors.black,
                                  path: 'assets/icons/pres.png',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(
                  height: 40,
                )
              ],
            ),
    );
  }

  //search stuff
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
              style: TextStyle(
                  color: weatherProvider.isNight ? Colors.white : Colors.black,
                  fontSize: 16),
              decoration: InputDecoration(
                hintText: "Plan your day – search for the city weather!",
                hintStyle: TextStyle(
                    color:
                        weatherProvider.isNight ? Colors.white : Colors.black,
                    fontSize: 12),
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
                  minWidth: 50,
                ),
                contentPadding: const EdgeInsets.only(left: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Close the keyboard
                    FocusScope.of(context).unfocus();

                    final city = _searchController.text;
                    if (city.isNotEmpty) {
                      if (weatherProvider.isConnected) {
                        weatherProvider.setCity = city;
                        weatherProvider.addCityToRecent(city);
                        weatherProvider.fetchd();
                        weatherProvider.fetchForecast();
                        weatherProvider.addCityToRecent(city);
                      } else {
                        showTopSnackBar(context);
                      }
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

  Widget _searchbox(WeatherProvider weatherProvider) {
    if (weatherProvider.showRecentSearches &&
        weatherProvider.recentSearches.isNotEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.only(top: 5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0), color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10.0, top: 10),
              child: buildText(input: 'Recent '),
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
                          // Close the keyboard
                          FocusScope.of(context).unfocus();

                          _searchController.text = city;
                          if (weatherProvider.isConnected) {
                            weatherProvider.setCity = (city);
                            weatherProvider.addCityToRecent(city);
                            weatherProvider.fetchd();
                            weatherProvider.fetchForecast();
                          } else {
                            showTopSnackBar(context);
                          }

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
            if (weatherProvider.recentSearches.length > 2) ...[
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
    return const SizedBox.shrink();
  }

  void showCountriesDialog(BuildContext context) {
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Country'),
          content: SizedBox(
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

    final cities = weatherProvider.citiesByCountry[country] ?? [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a City in $country'),
          content: SizedBox(
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
                    weatherProvider.setCity = selectedCity;
                    weatherProvider.fetchd();
                    weatherProvider.fetchForecast();
                    weatherProvider.addCityToRecent(selectedCity);

                    // print('Selected City: $selectedCity');
                    Navigator.of(context).pop();
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
