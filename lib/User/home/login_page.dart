import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:zeedz_attendance/dashboard_page.dart';
import 'package:zeedz_attendance/User/home/theme/colors.dart';
import 'package:zeedz_attendance/provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;

  String? emailError;
  String? passwordError;

  bool isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> handleLogin() async {
    setState(() {
      isLoading = true;
      emailError = null;
      passwordError = null;
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user == null) {
        throw Exception("User not found");
      }

      await context.read<PunchProvider>().loadProfile();
final provider = context.read<PunchProvider>();

// Create OneSignal user with Supabase user id
OneSignal.login(response.user!.id);

// Add tags
OneSignal.User.addTagWithKey(
  "role",
  provider.role,
);

OneSignal.User.addTagWithKey(
  "user_id",
  response.user!.id,
);

print("✅ OneSignal External ID = ${response.user!.id}");
print("✅ Role tag = ${provider.role}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(currentindex: 0)),
      );
    } on AuthException catch (e) {
      print("LOGIN ERROR: ${e.message}");

      setState(() {
        emailError = e.message;
        passwordError = "";
      });
    } catch (e) {
      print("LOGIN ERROR: $e");

      setState(() {
        emailError = "Login failed";
        passwordError = "Check credentials";
      });
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 60, color: Colors.blue),
                const SizedBox(height: 20),

                const Text(
                  "Company Login",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: size.height * 0.04),

                /// ✅ EMAIL
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: const OutlineInputBorder(),
                    errorText: emailError,
                  ),
                  onChanged: (_) {
                    setState(() {
                      emailError = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }

                    // ✅ SIMPLE VALIDATION (FIXED)
                    if (!value.contains('@') || !value.contains('.')) {
                      return "Enter valid email";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                /// ✅ PASSWORD
                TextFormField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    errorText: passwordError,
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
                  onChanged: (_) {
                    setState(() {
                      passwordError = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }

                    if (value.length < 6) {
                      return "Enter correct password";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                /// ✅ LOGIN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              handleLogin();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalblue,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}