import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PunchProvider>();
    final role = provider.role; //  get role
    final supabase = Supabase.instance.client;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4169E1), // Royal Blue
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            final user = supabase.auth.currentUser;
            if (user == null) return;

            if (role == 'superadmin') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("superAdmin cannot apply leave")),
              );
              return;
            }

            if (provider.leaveBalance <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No leave balance remaining")),
              );
              return;
            }
            if (provider.reason.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter reason")),
              );
              return;
            }

            if (provider.totalLeaveDays > provider.leaveBalance) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Only ${provider.leaveBalance} leave days available",
                  ),
                ),
              );
              return;
            }

            try {
              await supabase.from('leave_requests').insert({
                'user_id': user.id,
                'start_date': provider.startDate?.toIso8601String(),
                'end_date': provider.endDate?.toIso8601String(),
                'reason': provider.reason,
                'status': 'pending',
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Leave submitted successfully\nWait for approval",
                  ),
                ),
              ); Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.toString())));
            }
          },
          child: const Text(
            "Submit Leave",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
