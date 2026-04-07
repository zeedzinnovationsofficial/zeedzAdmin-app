import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class ProfileDetails extends StatefulWidget {
  const ProfileDetails({super.key});

  @override
  State<ProfileDetails> createState() => _ProfileDetailsState();
}

class _ProfileDetailsState extends State<ProfileDetails> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final punch = context.watch<PunchProvider>();
    @override
    // ignore: unused_element
    void initState() {
      super.initState();
      Future.microtask(() {
        context.read<PunchProvider>().loadProfile();
      });
    }

    print("PHOTO URL: ${punch.profileImageUrl}");
    print("IMAGE LENGTH: ${punch.profileImageUrl.length}");

    return Container(
      padding: const EdgeInsets.all(12),
      height: size.height * 0.24,
      width: size.width * 0.89,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: AppColors.lightgrey, blurRadius: 2)],
      ),
      child: Column(
        children: [
          ///  PROFILE IMAGE
          CircleAvatar(
            radius: size.width * 0.12,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: punch.profileImageUrl.isNotEmpty
                ? NetworkImage(punch.profileImageUrl)
                : null,
            child: punch.profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),

          SizedBox(height: size.height * 0.01),

          /// NAME
          Text(
            punch.name.isEmpty ? "Enter Name" : punch.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          SizedBox(height: size.height * 0.0),

          /// DEPARTMENT
          Text(punch.department.isEmpty ? "------" : punch.department),

          SizedBox(height: size.height * 0.0),

          Text(
            "ID: ${punch.employeeId ?? ''}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTag(String text, BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.03,
      width: size.width * 0.09,
      decoration: BoxDecoration(
        color: AppColors.shadowroyalblue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: AppColors.royalblue, fontSize: 10),
        ),
      ),
    );
  }
}
