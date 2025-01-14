## Weather App

   A Flutter-based weather app that provides weather information based on user input using the OpenWeather API.

## Prerequisites

   Before running the app, make sure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Make sure the `flutter` command is available in your terminal)
- [OpenWeatherMap API key](https://openweathermap.org/api) (Sign up for a free API key)

## Setting Up

   Follow the steps below to set up and run the app locally:

1. Clone the Repository

   Clone this repository to your local machine using the following command:

```bash
git clone
https://github.com/abidb7/weatherUpdate.git
```
2. Install Flutter Dependencies
   Navigate to the project folder and install the required Flutter dependencies:

```
cd weather-app
flutter pub get
```
   This will fetch all the necessary packages required for the project.

3. Obtain an OpenWeather API Key.
   
  Go to OpenWeatherMap and sign up for a free API key.
  After signing up, you'll get an API key that will be used to fetch weather data.
 
5. Set Up API Key in api.dart
   
  Open the api.dart file located in the lib folder of the project.
  In the file, you will find a placeholder for the API key like this:
  
  const  openWeatherApiKey = "YOUR_API_KEY";
  
  Replace YOUR_API_KEY with the API key you obtained from OpenWeatherMap

5. Run the Application
   Once the API key is set up, you can run the app on an emulator or a connected device:
  ```bash
    flutter run
  ```
   This will start the app, and you can use it to check the weather for different cities.

6. Access the App
   
  After running the app, open it on your device or emulator. The app will allow you to:
  
  Search for the weather of any city.
  
  View the current temperature, humidity, and weather conditions.
  
  Get a 5-day weather forecast.

## Features

  City Search: Search for the weather of any city.
  
  Current Weather: Displays current temperature, humidity, and weather conditions.
  
  Store Recently Seacherd cities.
  
  Forecast: View the 7-day weather forecast.

## Troubleshooting

  "API key not working": Ensure that your API key is correctly set in the api.dart file.
  "App not starting": Make sure you have installed all the dependencies using flutter pub get and that your device/emulator is properly configured.
  "Invalid city": Double-check the spelling of the city name and ensure it is recognized by the OpenWeather API.






