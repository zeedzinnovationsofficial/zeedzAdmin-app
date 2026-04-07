import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  List<AlarmSettings> alarms = [];
  bool repeatEveryday = false;
  String alarmType = "in"; // default punch in

  @override
  void initState() {
    super.initState();
    loadAlarms();

    // Listen when alarm rings
  }

  Future<void> loadAlarms() async {
    alarms = await Alarm.getAlarms();
    setState(() {});
  }

  /// OPEN CLOCK → SHOW REPEAT OPTION
  Future<void> openAlarmDialog() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Alarm Options",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Repeat Everyday",
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: repeatEveryday,
                        onChanged: (value) {
                          setStateSheet(() {
                            repeatEveryday = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      setAlarm(pickedTime, alarmType);
                      Navigator.pop(context);
                    },
                    child: const Text("Save Alarm"),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Alarm Type", style: TextStyle(fontSize: 16)),
                      DropdownButton<String>(
                        value: alarmType,
                        items: const [
                          DropdownMenuItem(
                            value: "in",
                            child: Text("Punch In"),
                          ),
                          DropdownMenuItem(
                            value: "out",
                            child: Text("Punch Out"),
                          ),
                        ],
                        onChanged: (value) {
                          setStateSheet(() {
                            alarmType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// SET ALARM
  Future<void> setAlarm(TimeOfDay time, String type) async {
    var status = await Permission.notification.status;

    if (!status.isGranted) {
      status = await Permission.notification.request();

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Notification permission is required for alarm."),
          ),
        );
        return; // stop setting alarm
      }
    }
    final now = DateTime.now();

    DateTime alarmDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (alarmDateTime.isBefore(now)) {
      alarmDateTime = alarmDateTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      dateTime: alarmDateTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volume: 0.9,
      fadeDuration: 3.0,
      notificationTitle: 'Attendance Alarm',
      notificationBody: type == "in"
          ? 'Time to punch in!'
          : 'Time to punch out!',
    );

    await Alarm.set(alarmSettings: alarmSettings);

    loadAlarms();
  }

  /// DELETE ALARM
  Future<void> deleteAlarm(int id) async {
    await Alarm.stop(id);
    loadAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alarm"),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: openAlarmDialog),
        ],
      ),

      body: alarms.isEmpty
          ? const Center(child: Text("No Alarms"))
          : ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarms[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightgrey.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      //  Icon + Time + Type
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightgrey.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alarm, size: 22),
                          ),

                          const SizedBox(width: 12),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('hh:mm a').format(alarm.dateTime),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                repeatEveryday
                                    ? "Repeat Everyday"
                                    : "One Time Alarm",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 🗑 Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          deleteAlarm(alarm.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
