import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/widget/employee_detail_tab.dart';

class EmployeeProfilePage extends StatefulWidget {
  final Map user;

  const EmployeeProfilePage({super.key, required this.user});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  bool showPassword = false;
  bool isEditing = false;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController deptController;
  late TextEditingController roleController;
  late TextEditingController salaryController;
  late TextEditingController emailController;
  late TextEditingController bloodController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user['name']);
    phoneController = TextEditingController(text: widget.user['phone']);
    deptController = TextEditingController(text: widget.user['department']);
    roleController = TextEditingController(text: widget.user['role']);
    salaryController =
        TextEditingController(text: widget.user['salary'].toString());
    emailController = TextEditingController(text: widget.user['email']);
    bloodController =
        TextEditingController(text: widget.user['blood_group']);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['name'] ?? "Employee"),
        backgroundColor: AppColors.white,
        actions: [
          /// ✏️ EDIT / 💾 SAVE
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () async {
              if (isEditing) {
                await saveData();
              }
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.shade50,
                backgroundImage:
                    widget.user['profile_image_url'] != null &&
                            widget.user['profile_image_url']
                                .toString()
                                .isNotEmpty
                        ? NetworkImage(widget.user['profile_image_url'])
                        : null,
                child:
                    widget.user['profile_image_url'] == null ||
                            widget.user['profile_image_url']
                                .toString()
                                .isEmpty
                        ? const Icon(Icons.person,
                            size: 50, color: Colors.blue)
                        : null,
              ),

              SizedBox(height: size.height * 0.02),

              /// NAME
              isEditing
                  ? TextField(controller: nameController)
                  : Text(
                      widget.user['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),

              SizedBox(height: size.height * 0.02),

              ListTile(
                leading: const Icon(Icons.assignment_ind_outlined),
                title: const Text("Employe ID"),
                subtitle: Text(widget.user['employee_id'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.business),
                title: const Text("Department"),
                subtitle: isEditing
                    ? TextField(controller: deptController)
                    : Text(widget.user['department'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.work),
                title: const Text("Role"),
                subtitle: isEditing
                    ? TextField(controller: roleController)
                    : Text((widget.user['role'] ?? "").toUpperCase()),
              ),

              ListTile(
                leading: const Icon(Icons.wallet_outlined),
                title: const Text("Salary"),
                subtitle: isEditing
                    ? TextField(controller: salaryController)
                    : Text(widget.user['salary'].toString()),
              ),

              ListTile(
                leading: const Icon(Icons.email),
                title: const Text("Email"),
                subtitle: isEditing
                    ? TextField(controller: emailController)
                    : Text(widget.user['email'] ?? "No Email"),
              ),

              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Password"),
                subtitle: Text(
                  showPassword
                      ? widget.user['password'] ?? ""
                      : "••••••••",
                ),
                trailing: IconButton(
                  icon: Icon(showPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                ),
              ),

              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text("Phone Number"),
                subtitle: isEditing
                    ? TextField(controller: phoneController)
                    : Text(widget.user['phone'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Join Date"),
                subtitle: Text(widget.user['joining_date'] ?? ""),
              ),

              ListTile(
                leading: const Icon(Icons.bloodtype),
                title: const Text("Blood Group"),
                subtitle: isEditing
                    ? TextField(controller: bloodController)
                    : Text(widget.user['blood_group'] ?? ""),
              ),

              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.shadowroyalblue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ),
                   onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EmployeeDetailsTab(
        user: Map<String, dynamic>.from(widget.user),
      ),
    ),
  );
},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "View All",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.royalblue,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.royalblue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SAVE
 Future<void> saveData() async {
  try {
    final response = await Supabase.instance.client
        .from('users')
        .update({
          'name': nameController.text,
          'phone': phoneController.text,
          'department': deptController.text,
          'role': roleController.text,
          'salary': salaryController.text.trim().isEmpty
           ? null
          : int.tryParse(salaryController.text),
          'email': emailController.text,
          'blood_group': bloodController.text,
        })
        .eq('id', widget.user['id']);

    print("Updated: $response");

    setState(() {
      widget.user['name'] = nameController.text;
      widget.user['phone'] = phoneController.text;
      widget.user['department'] = deptController.text;
      widget.user['role'] = roleController.text;
      widget.user['salary'] = salaryController.text;
      widget.user['email'] = emailController.text;
      widget.user['blood_group'] = bloodController.text;
    });

  } catch (e) {
    print("Error: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Update failed: $e")),
    );
  }
}
}