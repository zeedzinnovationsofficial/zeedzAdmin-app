import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HolidayPage extends StatefulWidget {
  const HolidayPage({super.key});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> holidays = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHolidays();
  }

  // 🔥 LOAD HOLIDAYS
  Future<void> loadHolidays() async {
    final response = await supabase
        .from('holidays')
        .select()
        .order('holiday_date');

    setState(() {
      holidays = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  // 🔥 ADD HOLIDAY
  Future<void> addHoliday(DateTime date, String name) async {
    final dateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    await supabase.from('holidays').insert({
      "holiday_date": dateStr,
      "name": name,
    });

    loadHolidays();
  }

  // 🔥 DELETE HOLIDAY
  Future<void> deleteHoliday(String id) async {
    await supabase.from('holidays').delete().eq('id', id);
    loadHolidays();
  }

  // 🔥 ADD HOLIDAY DIALOG
  Future<void> showAddHolidayDialog(DateTime pickedDate) async {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Holiday"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Enter reason (e.g. Pongal, Diwali)",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter holiday reason")),
                  );
                  return;
                }

                await addHoliday(pickedDate, name);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🔥 PICK DATE
  Future<void> pickDateAndAddHoliday() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      showAddHolidayDialog(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // 🔥 background

      appBar: AppBar(
        title: const Text(
          "Manage Holidays",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.blue),
            onPressed: pickDateAndAddHoliday,
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : holidays.isEmpty
          ? const Center(child: Text("No holidays added"))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                itemCount: holidays.length,
                itemBuilder: (context, index) {
                  final holiday = holidays[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, // 🔥 white card
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        /// 📅 ICON
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holiday['name'] ?? "Holiday",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(
                                  DateTime.parse(holiday['holiday_date']),
                                ),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// ❌ DELETE
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          onPressed: () => deleteHoliday(holiday['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
