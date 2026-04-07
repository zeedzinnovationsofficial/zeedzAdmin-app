import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final supabase = Supabase.instance.client;
  bool isPasswordVisible = false;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final departmentController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final employeeIdController = TextEditingController();

  DateTime selectedJoiningDate = DateTime.now();
  String selectedRole = 'employee';
  String selectedDepartment = "Software";
  bool isLoading = false;
  String workSchedule = "mon_sat";
  File? selectedImage;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(String userId) async {
    if (selectedImage == null) return null;

    final fileExt = selectedImage!.path.split('.').last;
    final filePath = '$userId.$fileExt';

    await supabase.storage.from('avatars').upload(filePath, selectedImage!);

    final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
    return imageUrl;
  }

  Future<void> createUser() async {
    setState(() => isLoading = true);

    try {
      /// SAVE CURRENT SESSION (superadmin/admin/hr)
      final currentSession = supabase.auth.currentSession;

      final currentUserRole = context.read<PunchProvider>().role;
      String finalRole = selectedRole;

      if (currentUserRole == 'hr') {
        finalRole = 'employee';
      }

      /// CREATE AUTH USER
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final newUser = response.user;
      if (newUser == null) throw Exception("Auth user creation failed");

      /// RESTORE ADMIN SESSION
      if (currentSession != null) {
        await supabase.auth.setSession(currentSession.refreshToken!);
      }

      /// UPLOAD IMAGE
      final imageUrl = await uploadImage(newUser.id);

      /// INSERT USER DATA
      await supabase.from('users').insert({
        'id': newUser.id,
        'employee_id': employeeIdController.text.trim(),
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'phone': phoneController.text.trim(),
        'department': selectedDepartment,
        'work_schedule': workSchedule,
        'joining_date': selectedJoiningDate.toIso8601String(),
        'blood_group': bloodGroupController.text.trim(),
        'profile_image_url': imageUrl,
        'role': finalRole,
        'leave_balance': 12,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Created Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final role = context.watch<PunchProvider>().role;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add User"),
        backgroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              //  Profile Image
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: size.width * 0.12,
                  backgroundImage: selectedImage != null
                      ? FileImage(selectedImage!)
                      : null,
                  child: selectedImage == null
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),
              ),
              SizedBox(height: size.height * 0.018),

              TextField(
                controller: employeeIdController,
                decoration: const InputDecoration(labelText: "Employee ID"),
              ),
              SizedBox(height: size.height * 0.015),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              SizedBox(height: size.height * 0.015),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              SizedBox(height: size.height * 0.015),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.015),

              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              SizedBox(height: size.height * 0.015),

              DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: const InputDecoration(labelText: "Department"),
                items: const [
                  DropdownMenuItem(value: "Software", child: Text("Software")),
                  DropdownMenuItem(value: "Designer", child: Text("Designer")),
                  DropdownMenuItem(value: "HR", child: Text("HR")),
                  DropdownMenuItem(value: "Interns", child: Text("Interns")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedDepartment = value!;
                  });
                },
              ),
              SizedBox(height: size.height * 0.015),

              DropdownButtonFormField<String>(
                value: workSchedule,
                decoration: const InputDecoration(labelText: "Work Schedule"),
                items: const [
                  DropdownMenuItem(
                    value: "mon_fri",
                    child: Text("Monday - Friday"),
                  ),
                  DropdownMenuItem(
                    value: "mon_sat",
                    child: Text("Monday - Saturday"),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    workSchedule = value!;
                  });
                },
              ),
              SizedBox(height: size.height * 0.015),

              TextField(
                controller: bloodGroupController,
                decoration: const InputDecoration(labelText: "Blood Group"),
              ),
              SizedBox(height: size.height * 0.015),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Joining Date: ${selectedJoiningDate.toLocal().toString().split(' ')[0]}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedJoiningDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => selectedJoiningDate = picked);
                  }
                },
              ),

              if (role == 'superadmin')
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text("Employee"),
                    ),
                    DropdownMenuItem(value: 'hr', child: Text("HR")),
                    DropdownMenuItem(value: 'admin', child: Text("Admin")),
                    DropdownMenuItem(value: 'intern', child: Text("Intern")),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                  decoration: const InputDecoration(labelText: "Role"),
                ),
              if (role == 'admin')
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text("Employee"),
                    ),
                    DropdownMenuItem(value: 'hr', child: Text("HR")),
                    DropdownMenuItem(value: 'intern', child: Text("Intern")),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                  decoration: const InputDecoration(labelText: "Role"),
                ),
              if (role == 'hr')
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text("Employee"),
                    ),

                    DropdownMenuItem(value: 'intern', child: Text("Intern")),
                  ],
                  onChanged: (value) {
                    setState(() => selectedRole = value!);
                  },
                  decoration: const InputDecoration(labelText: "Role"),
                ),

              SizedBox(height: size.height * 0.015),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createUser,

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create User"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
