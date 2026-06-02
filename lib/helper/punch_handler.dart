import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class PunchHandler {

 static Future<void> punchIn(
  BuildContext context,
) async {
  final picker = ImagePicker();

  final XFile? photo = await picker.pickImage(
    source: ImageSource.camera,
  );

  if (photo == null) return;

  try {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final position =
        await Geolocator.getCurrentPosition();

    final placemarks =
        await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.first;

    final address =
        "${place.locality}, ${place.administrativeArea}, ${place.country}";

    await context.read<PunchProvider>().punchIn(
      address,
      context,
    );

    await context.read<PunchProvider>().loadTodayPunch();

  } catch (e) {
    debugPrint("PunchIn Error: $e");
  }
}

  static Future<void> punchOut(
  BuildContext context,
) async {
  final picker = ImagePicker();

  final XFile? photo =
      await picker.pickImage(
    source: ImageSource.camera,
  );

  if (photo == null) return;

  try {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    final position =
        await Geolocator.getCurrentPosition();

    final placemarks =
        await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.first;

    final address =
        "${place.locality}, ${place.administrativeArea}, ${place.country}";

    await context.read<PunchProvider>().punchOut(
      location: address,
      context: context,
    );

    await context.read<PunchProvider>().loadTodayPunch();

  } catch (e) {
    debugPrint("PunchOut Error: $e");
  }
}

}