import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HF {
  static final HF shared = HF();

  String calculateTimeDifference(String from, String to) {
    // Parse the time strings
    List<int> parts1 = from.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> parts2 = to.split(':').map((e) => int.tryParse(e) ?? 0).toList();

    // Convert the times to minutes
    int minutes1 = parts1[0] * 60 + parts1[1];
    int minutes2 = parts2[0] * 60 + parts2[1];

    // Calculate the absolute difference in minutes
    int differenceInMinutes = 0;

    // If the second time is earlier than the first time, it means it's the next day
    if (minutes2 < minutes1) {
      differenceInMinutes = (24 * 60) - minutes1 + minutes2;
    } else {
      differenceInMinutes = (minutes2 - minutes1).abs();
    }

    // Convert the difference back to HH:mm format
    int hours = differenceInMinutes ~/ 60;
    int minutes = differenceInMinutes % 60;

    // Format the result as HH:mm
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String remainingTime(List<String> prayerTimes) {
    // final fake = "22:00";
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final nextTime = findNextPrayerTime(currentTime, prayerTimes);

    return calculateTimeDifference(currentTime, nextTime);
  }

  String findNextPrayerTime(String currentTime, List<String> prayerTimes) {
    final ct = DateFormat('HH:mm').parse(currentTime, true);

    for (String prayerTime in prayerTimes) {
      if (prayerTime.isEmpty) {
        continue;
      }
      DateTime prayerDateTime = DateFormat('HH:mm').parse(prayerTime, true);
      if (prayerDateTime.isAfter(ct)) {
        return prayerTime;
      }
    }
    return prayerTimes.first;
  }

  int findNextPrayerTimeIndex(List<String> prayerTimes) {
    final currentTime = DateFormat('HH:mm').format(DateTime.now());
    final ct = DateFormat('HH:mm').parse(currentTime, true);

    for (final prayerTime in prayerTimes.asMap().entries) {
      if (prayerTime.value.isEmpty) {
        continue;
      }
      DateTime prayerDateTime = DateFormat('HH:mm').parse(prayerTime.value, true);
      if (prayerDateTime.isAfter(ct)) {
        return prayerTime.key;
      }
    }
    return 0;
  }

  int findCurrentPrayerTimeIndex(List<String> prayerTimes) {
    final nextPrayerTime = findNextPrayerTimeIndex(prayerTimes);

    if (nextPrayerTime == 0) {
      return prayerTimes.length - 1;
    }
    return nextPrayerTime - 1;
  }

  Color getColorForCurrentTime(List<String> prayerTimes, int currentIndex) {
    final index = findCurrentPrayerTimeIndex(prayerTimes);

    return currentIndex == index ? Colors.green : Colors.black;
  }

  Color getColorForRemainingTime(String remainingTime) {
    // Define thresholds for color change
    String greenThreshold = '01:30';
    String blueThreshold = '01:00';

    // Perform string comparison
    if (remainingTime.compareTo(greenThreshold) > 0) {
      return Colors.green;
    } else if (remainingTime.compareTo(blueThreshold) > 0) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  bool isRunningOnSimulator() {
    if (Platform.isIOS || Platform.isAndroid) {
      // Check if running on a simulator or emulator
      return !(Platform.isIOS && !stdout.hasTerminal);
    }
    return false; // For other platforms, assume it's a real device
  }
}


final mockData = {
  "place": {
    "countryCode": "TR",
    "country": "Turkey",
    "region": "Ankara",
    "city": "Ankara",
    "latitude": 39.91987,
    "longitude": 32.85427
  },
  "times": {
    "2023-10-29": [
      "05:42",
      "07:07",
      "12:37",
      "15:29",
      "17:58",
      "19:16"
    ]
  }
};