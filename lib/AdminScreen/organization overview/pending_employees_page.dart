// import 'package:flutter/material.dart';
 //import 'package:provider/provider.dart';
 //import 'package:zeedz_attendance/provider/provider.dart';
 //import 'package:zeedz_attendance/User/home/theme/colors.dart';

 //class PendingEmployeesPage extends StatefulWidget {
   //const PendingEmployeesPage({super.key});

   //@override
   //State<PendingEmployeesPage> createState() => _PendingEmployeesPageState();
 //}

 //class _PendingEmployeesPageState extends State<PendingEmployeesPage> {
   //@override
   //Widget build(BuildContext context) {
     //final size = MediaQuery.of(context).size;
     //final punch = context.watch<PunchProvider>();

     //final employees = punch.todayPendingEmployeesList;

     //return Scaffold(
       //appBar: AppBar(
       // title: const Text("Pending Employees"),
         //backgroundColor: AppColors.white,
       //),

       //body: employees.isEmpty
         //  ? const Center(child: Text("No Employees Pending Today"))
           //: ListView.builder(
             //  itemCount: employees.length,
               //itemBuilder: (context, index) {
                 //final user = employees[index];

                 //return Container(
                  //margin: const EdgeInsets.symmetric(
                    // horizontal: 15,
                     //vertical: 8,
                  // ),
                   //padding: const EdgeInsets.all(12),
                   //height: size.height * 0.12,

                   //decoration: BoxDecoration(
                     //color: AppColors.white,
                     //borderRadius: BorderRadius.circular(10),
                     //boxShadow: const [
                     // BoxShadow(
                       //  color: AppColors.lightgrey,
                         //blurRadius: 2,
                         //offset: Offset(0, 0),
                      //),
                    //],
                   //),

                  //child: Row(
                    // children: [
                       /// PROFILE ICON
                      // CircleAvatar(
                        //radius: 26,
                        //backgroundColor: Colors.orange.shade50,
                         //child: const Icon(Icons.person, color: Colors.orange),
                       //),

                       //const SizedBox(width: 15),

                      /// USER DETAILS
                       //Expanded(
                         //child: Column(
                           //crossAxisAlignment: CrossAxisAlignment.start,
                           //mainAxisAlignment: MainAxisAlignment.center,
                           //children: [
                             //Text(
                              //user['name'] ?? 'No Name',
                               //style: const TextStyle(
                                 //fontWeight: FontWeight.bold,
                                 //fontSize: 16,
                               //),
                             //),

                             //const SizedBox(height: 5),

                             //Text(
                               //"Department: ${user['department'] ?? ''}",
                             // style: const TextStyle(color: Colors.grey),
                            //),

                             //const SizedBox(height: 8),

                            /// STATUS BADGE
                             //Container(
                               //padding: const EdgeInsets.symmetric(
                                 //horizontal: 10,
                                //vertical: 4,
                              //),

                               //decoration: BoxDecoration(
                                //color: Colors.orange.shade100,
                                //borderRadius: BorderRadius.circular(20),
                              //),

                              //child: const Text(
                                // "PENDING",
                                 //style: TextStyle(
                                   //fontSize: 12,
                                   //fontWeight: FontWeight.w600,
                                   //color: Colors.orange,
                                //),
                               //),
                             //),
                          //],
                         //),
                       //),
                    //],
                   //),
                //);
               //},
            //),
    //);
   //}
 //}
