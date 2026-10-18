
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

const apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool isLoading = true;

  String city = '';
  String temperature = '';
  String description = '';
  String humidity = '';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    getWeather();
  }

  void getWeather() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      if (apiKey.isEmpty) {
        throw Exception('OpenWeatherMap API key is missing.');
      }

      bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please enable location services.');
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.low,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      double latitude = position.latitude;
      double longitude = position.longitude;

      String url =
          'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$latitude&lon=$longitude'
          '&appid=$apiKey&units=imperial';

      http.Response response =
      await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
          'Weather request failed: ${response.statusCode}',
        );
      }

      var data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        city = data['name'].toString();
        temperature = data['main']['temp'].toString();
        description =
            data['weather'][0]['description'].toString();
        humidity = data['main']['humidity'].toString();

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            error.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Weather'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(
        child: SpinKitDualRing(
          color: Colors.blue,
          size: 60,
        ),
      )
          : Center(
        child: errorMessage.isNotEmpty
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: getWeather,
              child: const Text('Try Again'),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wb_cloudy,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              city,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 20),
            Text(
              '$temperature °F',
              style: const TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Humidity: $humidity%',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
