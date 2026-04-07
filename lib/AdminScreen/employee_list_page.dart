import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zeedz_attendance/AdminScreen/add_user_page.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class EmployeeListPage extends StatefulWidget {
  const EmployeeListPage({super.key});

  @override
  State<EmployeeListPage> createState() => _EmployeeListPageState();
}

class _EmployeeListPageState extends State<EmployeeListPage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await supabase
        .from('users')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateRole(String userId, String newRole) async {
    try {
      await supabase.from('users').update({'role': newRole}).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Role Updated Successfully")),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> deleteUser(String userId) async {
    final currentUser = supabase.auth.currentUser;

    if (currentUser?.id == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot delete yourself")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('users').delete().eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Deleted Successfully")),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentRole = context.watch<PunchProvider>().role;
    // ignore: unused_local_variable
    final punch = Provider.of<PunchProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
        actions: [
          if (currentRole == 'admin' ||
              currentRole == 'hr' ||
              currentRole == 'superadmin')
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: "Add Employee",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserPage()),
                );
                setState(() {});
              },
            ),
        ],
        backgroundColor: AppColors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          if (users.isEmpty) {
            return const Center(child: Text("No Employees Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: EdgeInsets.all(12),
                height: size.height * 0.13,
                width: size.width * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightgrey,
                      blurRadius: 2,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    /// Profile Circle
                    CircleAvatar(
                      radius: size.width * 0.06,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          user['profile_image_url'] != null &&
                              user['profile_image_url'].toString().isNotEmpty
                          ? NetworkImage(user['profile_image_url'])
                          : null,
                      child:
                          user['profile_image_url'] == null ||
                              user['profile_image_url'].toString().isEmpty
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),

                    SizedBox(width: size.width * 0.08),

                    /// User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: size.height * 0.01),
                          Text(
                            "Department: ${user['department'] ?? ''}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          SizedBox(height: size.height * 0.01),

                          /// Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: user['role'] == 'superadmin'
                                  ? Colors.red.shade100
                                  : user['role'] == 'admin'
                                  ? Colors.purple.shade100
                                  : user['role'] == 'hr'
                                  ? Colors.orange.shade100
                                  : user['role'] == 'intern'
                                  ? Colors.blue.shade100
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (user['role'] ?? '').toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: user['role'] == 'superadmin'
                                    ? Colors.red
                                    : user['role'] == 'admin'
                                    ? Colors.purple
                                    : user['role'] == 'hr'
                                    ? Colors.orange
                                    : user['role'] == 'intern'
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Admin Controls
                    if (currentRole == 'superadmin' ||
                        currentRole == 'admin' ||
                        currentRole == 'hr')
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            if (user['role'] == 'superadmin') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("SuperAdmin cannot be deleted"),
                                ),
                              );
                              return;
                            }

                            bool confirm = await confirmAction(
                              "Confirm you want delete ${user['name']} ?",
                            );

                            if (confirm) {
                              await deleteUser(user['id']);
                            }
                          } else {
                            String roleText = value == "admin"
                                ? "Admin"
                                : value == "hr"
                                ? "HR"
                                : "Employee";

                            bool confirm = await confirmAction(
                              "Confirm you want make ${user['name']} $roleText ?",
                            );

                            if (confirm) {
                              await updateRole(user['id'], value);
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'admin',
                            child: Text("Make Admin"),
                          ),
                          PopupMenuItem(value: 'hr', child: Text("Make HR")),
                          PopupMenuItem(
                            value: 'employee',
                            child: Text("Make Employee"),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              "Delete User",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> confirmAction(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
