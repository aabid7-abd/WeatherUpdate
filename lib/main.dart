// main.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forecast/screen.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../Api.dart';
import 'StateManage.dart';
Future<void> main() async {

    WidgetsFlutterBinding.ensureInitialized();

    final weatherProvider = WeatherProvider();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    runApp(
      ChangeNotifierProvider(
        create: (_) => weatherProvider,
        child: const MyApp(),
      ),

    );
  }



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Homescreen(),
    );
  }
}







