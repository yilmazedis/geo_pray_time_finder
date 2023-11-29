import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geo_pray_time_finder/services/location_manager.dart';
import 'package:geo_pray_time_finder/utils/extensions/int+ext.dart';
import 'package:geo_pray_time_finder/utils/extensions/string+ext.dart';
import 'package:geo_pray_time_finder/utils/functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:time_listener/time_listener.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GeoService geoService = GeoService();
  final prayTimeNames = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"];
  int selectedTimezoneOffset = 480;
  List<int> timezoneOffsets = [-720, -600, -480, -360, -300, -240, -180, -120, 0, 60, 120, 180, 240, 300, 330, 345, 360, 390, 420, 480, 525, 540, 570, 600, 630, 660, 690, 720, 765, 780, 840];
  TimeListener? listener;
  String remainingTime = "";
  String nextSalahTime = "";
  bool _shouldUpdate = true;
  Future<Map<String, dynamic>>? futureData;

  Future<Map<String, dynamic>> fetchData() async {
    return fetchSalahTimes();
    // print("Fetch Salah Data");
    // if (HF.shared.isRunningOnSimulator()) {
    //   return mockData;
    // } else {
    //   return fetchSalahTimes();
    // }
  }

  Future<Map<String, dynamic>> fetchSalahTimes() async {
    final location = await _findPrayTime();
    final lat = location['latitude'] ?? 0;
    final lng = location['longitude'] ?? 0;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final response = await http.get(Uri.parse(
        'https://namaz-vakti.vercel.app/api/timesFromCoordinates?lat=$lat&lng=$lng&date=$date&days=1&timezoneOffset=$selectedTimezoneOffset&calculationMethod=Turkey'));

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON data
      return json.decode(response.body);
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, double>> _findPrayTime() async {
    bool serviceEnabled = await geoService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled. Enabling...');
      await geoService.requestLocationService();
    }

    bool hasPermission = await geoService.hasLocationPermission();
    if (!hasPermission) {
      print('Location permission not granted. Requesting...');
      await geoService.requestLocationPermission();
    }

    Map<String, double> location = await geoService.getLocation();
    print('Latitude: ${location['latitude']}, Longitude: ${location['longitude']}');
    return location;
  }

  void _updateData() {
    // Toggle the flag and trigger a rebuild
    setState(() {
      _shouldUpdate = !_shouldUpdate;
    });
  }

  @override
  void initState() {
    futureData = fetchData();
    super.initState();
  }

  @override
  void dispose() {
    listener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Namaz Times'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: FutureBuilder<Map<String, dynamic>>(
            future: futureData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                // Process and display the data
                Map<String, dynamic> responseData = snapshot.data!;
                Map<String, dynamic> placeData = responseData['place'];
                Map<String, dynamic> timesData = responseData['times'];

                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    width: 385,
                    height: 540,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.green
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location: ${placeData['city']}, ${placeData['region']}, ${placeData['country']}',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Latitude: ${placeData['latitude']}',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Longitude: ${placeData['longitude']}',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 20),
                          const Text(
                            'Namaz Times:',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: timesData.keys.map((date) {
                              List<String> prayerTimes = List<String>.from(timesData[date]);

                              if (listener == null) {
                                nextSalahTime = prayTimeNames[HF.shared.findNextPrayerTimeIndex(prayerTimes)];
                                remainingTime = HF.shared.remainingTime(prayerTimes);
                                listener = TimeListener.create(interval: CheckInterval.seconds)..listen((DateTime dt) {
                                  setState(() {
                                    nextSalahTime = prayTimeNames[HF.shared.findNextPrayerTimeIndex(prayerTimes)];
                                    remainingTime = HF.shared.remainingTime(prayerTimes);
                                  });
                                });
                              }
                              return Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0), // Set the corner radius here
                                    color: Colors.white
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date: ${date.formatToCustomDate()}',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 5),
                                      for (MapEntry<int, String> entry in prayerTimes.asMap().entries)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  prayTimeNames[entry.key],
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: HF.shared
                                                          .getColorForCurrentTime(
                                                              prayerTimes,
                                                              entry.key)),
                                                ),
                                                Text(
                                                  entry.value,
                                                  style: TextStyle(fontSize: 18, color: HF.shared
                                                      .getColorForCurrentTime(
                                                      prayerTimes,
                                                      entry.key)),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 1, color: Colors.grey),
                                          ],
                                        ),

                                      Padding(padding: const EdgeInsets.only(top: 20, bottom: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              const Text("To ", style: TextStyle(fontSize: 16),),
                                              Text(nextSalahTime, style: const TextStyle(fontSize: 20),),
                                              const SizedBox(width: 10),
                                              Text(
                                                remainingTime,
                                                style: TextStyle(
                                                    fontSize: 21,
                                                    color: HF.shared.getColorForRemainingTime(remainingTime),
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          )
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select Timezone: UTC:', style: TextStyle(fontSize: 18),),
            const SizedBox(width: 10),
            DropdownButton<int>(
              value: selectedTimezoneOffset,
              items: timezoneOffsets.map((int offset) {
                return DropdownMenuItem<int>(
                  value: offset,
                  child: Text(offset.divideTime(), style: const TextStyle(fontSize: 18),),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  futureData = fetchData();
                  selectedTimezoneOffset = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}