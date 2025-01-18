import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_animation/weather_animation.dart';

import 'StateManage.dart';

String getWindSpeed(double? windSpeed, BuildContext context) {
  final weatherProvider = Provider.of<WeatherProvider>(context);
  String u = weatherProvider.unit;

  if (windSpeed == null) return 'N/A';
  if (u == "°") {
    return '${windSpeed.toStringAsFixed(1)} m/s'; // For metric (m/s)
  } else if (u == "F") {
    double ws = windSpeed * 2.237;
    return '${ws.toStringAsFixed(1)} mph'; // For imperial (mph)
  } else {
    return 'N/A';
  }
}

Widget buildErrorUI(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: Colors.blue,
        ),
        Text(message, style: const TextStyle(color: Colors.black)),
      ],
    ),
  );
}

Color getColorBasedOnWeather(String description) {
  switch (description.toLowerCase()) {
    case 'clear sky':

      return const Color(0xff87ceeb); // For clear sky (sunny weather)
    case 'few clouds':
    case 'scattered clouds':
    case 'broken clouds':
    case 'overcast clouds':
      return const Color(0xffd3d3d3); // For cloudy weather
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
      return Color(0xffbcc8d3);

    case 'haze':
      return const Color(0xffd7ccc8);
    case 'fog':
      return const Color(0xffd0d6db);
    default:
      return Colors
          .blue; // For default (e.g., if the description is not recognized)
  }
}

String capitalizeEachWord(String input) {
  if (input.isEmpty) return input;

  return input.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}

Widget buildText({required String input, Color? color = Colors.black}) {
  return Text(
    input,
    style: TextStyle(
      fontSize: 14,
      color: color,
    ),
  );
}

Widget sun(String p,String text,String path, BuildContext context) {

  return     Row(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      SizedBox(
        width: 35,
        height: 35,

        child: Image.asset(path),
      ),
      const SizedBox(
        width: 5,
      ),
      buildText(input:text,color: Colors.white),

    ],

  );
}

String getWindSpeedDescription(double? windSpeed) {
  if (windSpeed == null) return 'N/A';

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

Widget buildWeatherInfoColumn(
    {required String value,
    required String label,
    Color color = Colors.white,
    double fontSize = 14,
    required String path}) {
  return label != "Temperature"
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(path),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              value,
              style: TextStyle(color: color, fontSize: fontSize),
            ),
            Text(
              label,
              style: TextStyle(color: color),
            ),
          ],
        )
      : Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(path),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(color: color, fontSize: fontSize),
            ),
          ],
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
            return !weatherProvider.isNight
                ?
            const WrapperScene(colors: [
                    Color(0xff87ceeb),
                    Color(0xff4682b4),
                  ], children: [
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
                  ])
                : const WrapperScene(
                    colors: [
                      Color(0xffffffff),
                      Color(0xff0f2027),
                      Color(0xff0f2027),
                      Color(0xff0f2027),
                      Color(0xff203a43),
                      Color(0xff2c5364)
                    ],
                    children: [],
                  );
          case "cloudy":
            return WrapperScene(
              colors: const [
                Color(0xffd3d3d3),
                Color(0xffa9a9a9),
              ],
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Transform.scale(
                    scale: 0.4,
                    child: const CloudWidget(),
                  ),
                ),
                SizedBox(
                  width: 120,
                  height: MediaQuery.of(context).size.height * 1,
                  child: Transform.scale(
                    scale: 0.2,
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
          case "haze":
            return const WrapperScene(
              colors: [
                Color(0xffd7ccc8), // Light haze with a soft brownish-gray tint
                Color(
                    0xffc7c3be), // Slightly darker haze with a hint of yellowish-gray
              ],
              children: [],
            );
          case "mist":
            return const WrapperScene(
              colors: [
                Color(0xffd3e7ee), // Light mist with a bluish-gray tone
                Color(0xffbcc8d3), // Slightly deeper gray-blue mist
              ],
              children: [],
            );
          case "fog":
            return const WrapperScene(
              colors: [
                Color(0xffd0d6db), // Soft foggy gray
                Color(0xffa9b1b7), // Dense, darker fog
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

Widget buildWeatherIcon(WeatherProvider weatherProvider) {
  bool isNight = weatherProvider.isNight;
  final weatherDescription =
      weatherProvider.weather?.weatherDescription?.toLowerCase() ?? "";
  if (weatherDescription == "clear sky") {
    return !isNight
        ? Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/sun.png'),
              ),
            ),
          )
        : Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/night.png'),
              ),
            ),
          );
  } else {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://openweathermap.org/img/wn/${weatherProvider.weather?.weatherIcon}@4x.png',
          ),
        ),
      ),
    );
  }
}

Widget buildMinMax(
    {double? temperatureMax, double? temperatureMin, required String unit}) {
  return Row(
    children: [
      const Icon(Icons.arrow_upward, color: Colors.white, size: 15),
      const SizedBox(width: 5),
      Text(
        '${temperatureMax?.toStringAsFixed(0)} $unit',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      const SizedBox(width: 10),
      const Text(
        '/',
        style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      const SizedBox(width: 10),
      Text(
        '${temperatureMin?.toStringAsFixed(0)} $unit',
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
      ),
      const Icon(Icons.arrow_downward, size: 15, color: Colors.white)
    ],
  );
}

double ftc(double fahrenheit) {
  return (fahrenheit - 32) * 5 / 9;
}

double ctf(double celsius) {
  return (celsius * 9 / 5) + 32;
}

void showTopSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Can't reach the internet. Please check your connection.",
        style: TextStyle(color: Colors.white),
      ),
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.black,
      margin: EdgeInsets.only(top: 50, left: 10, right: 10),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
    ),
  );
}

String getHumidityLevelDescription(double humidity) {
  if (humidity < 0 || humidity > 100) {
    throw ArgumentError("Humidity level must be between 0 and 100.");
  }

  if (humidity >= 0 && humidity <= 20) {
    return "Very Dry";
  } else if (humidity > 20 && humidity <= 40) {
    return "Dry";
  } else if (humidity > 40 && humidity <= 60) {
    return "Comfortable";
  } else if (humidity > 60 && humidity <= 80) {
    return "Humid";
  } else {
    return "Very Humid";
  }
}

String getPressureLevel(double pressureHpa) {
  if (pressureHpa < 980) {
    return "Low";
  } else if (pressureHpa >= 980 && pressureHpa < 1020) {
    return "Normal";
  } else {
    return "High";
  }
}
