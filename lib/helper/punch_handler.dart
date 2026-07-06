import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class PunchHandler {

  static Future<void> punchIn(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please turn ON Location")),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      final address = "${place.locality}, ${place.administrativeArea}, ${place.country}";

      await context.read<PunchProvider>().punchIn(address, context);
      await context.read<PunchProvider>().loadTodayPunch();
    } catch (e) {
      debugPrint("PunchIn Error: $e");
    }
  }

  static Future<void> punchOut(BuildContext context) async {
    final now = DateTime.now();

  if (now.weekday == DateTime.sunday) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Punch In / Punch Out is not available on weekends"),
      ),
    );
    return;
  }
    final picker = ImagePicker();
     
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    try {
      final now = DateTime.now();
      final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final userId = Supabase.instance.client.auth.currentUser!.id;

   
      await Supabase.instance.client.from('attendance').update({
        'punch_out': now.toIso8601String(),
      }).eq('user_id', userId).eq('date', todayStr);

      
      await calculateAndSaveSalaryOnPunchOut(userId, todayStr, now);

      await context.read<PunchProvider>().loadTodayPunch();
    } catch (e) {
      debugPrint("PunchOut Error: $e");
    }
  }

  
  static Future<void> calculateAndSaveSalaryOnPunchOut(String userId, String todayDate, DateTime now) async {
    final supabase = Supabase.instance.client;

    if (now.weekday == DateTime.sunday) {
    return;
  }
    final userRes = await supabase.from('users').select('salary').eq('id', userId).single();
    double monthlySalary = (userRes['salary'] ?? 0).toDouble();

    final cycleStart = DateTime(now.year, now.month, 1);
    final cycleEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    
    int payableDays = 0;
    for (DateTime d = cycleStart; !d.isAfter(cycleEnd); d = d.add(const Duration(days: 1))) {
      if (d.weekday != DateTime.sunday) payableDays++;
    }

    double perDay = monthlySalary / payableDays;
    double perHour = perDay / 8;

    final attRes = await supabase.from('attendance').select().eq('user_id', userId).eq('date', todayDate).maybeSingle();
    if (attRes == null || attRes['punch_in'] == null) return;
// ⚠️ TIMEZONE IGNORE FIX: உங்களது parsePunchIn மெத்தடில் உள்ள அதே லாஜிக்
    final rawPunchIn = DateTime.parse(attRes['punch_in'].toString());
    final punchIn = DateTime(rawPunchIn.year, rawPunchIn.month, rawPunchIn.day, rawPunchIn.hour, rawPunchIn.minute, rawPunchIn.second);
    final punchOut = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);

    
    double workedHours = punchOut.difference(punchIn).inMinutes / 60.0;
    double lateHours = 0;
    
    final startTime = DateTime(punchIn.year, punchIn.month, punchIn.day, 9, 30);
    if (punchIn.isAfter(startTime)) {
      lateHours = punchIn.difference(startTime).inMinutes / 60.0;
    }

    double finalExtraHours = workedHours > 8 ? (workedHours - 8) : 0;
    double normalWork = workedHours > 8 ? 8 : (workedHours < 0 ? 0 : workedHours);

    
    double earnedToday = normalWork * perHour;
    double totalDeductionToday = lateHours * perHour; 
    double extraEarn = finalExtraHours * perHour;


    double remainingDeduction = totalDeductionToday - extraEarn;
    double finalExtraEarning = 0;
    if (remainingDeduction < 0) {
      finalExtraEarning = -remainingDeduction;
      remainingDeduction = 0;
    }

  
    double finalNetEarning = earnedToday + finalExtraEarning;
    if (finalNetEarning < 0) finalNetEarning = 0;

    await supabase.from('attendance').update({
      'earned_amount': finalNetEarning,
      'deductions': remainingDeduction,
    }).eq('id', attRes['id']);
    
    print("Punchout Auto Salary Update Success! Earned: $finalNetEarning, Deductions: $remainingDeduction");
  }
}