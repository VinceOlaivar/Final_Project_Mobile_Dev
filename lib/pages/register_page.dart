import 'package:final_project/services/auth/auth_service.dart';
import 'package:final_project/components/my_button.dart';
import 'package:final_project/components/my_textfield.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text Controllers for Auth
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  // Text Controllers for Profile Data (All fields are now optional for a generic user profile)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idNumberController = TextEditingController(); 
  final TextEditingController departmentOrCourseController = TextEditingController(); 
  final TextEditingController ageController = TextEditingController();

  // Register Method
  void register(BuildContext context) async {
    final auth = AuthService();

    // 1. Password Check
    if (pwController.text.trim() != confirmPwController.text.trim()) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Passwords do not match!"),
          ),
        );
      }
      return;
    }
    
    // 2. Try to register
    try {
      // Collect user data (the 'role' is now defaulted to 'General' in AuthService)
      Map<String, dynamic> userData = {
        "name": nameController.text.trim(),
        "idNumber": idNumberController.text.trim(),
        "departmentOrCourse": departmentOrCourseController.text.trim(),
        "age": ageController.text.trim(),
      };
      
      // Call the simplified signup method
      await auth.signUpWithEmailAndPassword(
        emailController.text.trim(),
        pwController.text.trim(),
        userData, // Pass the rest of the profile data
      );

    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Registration Error"),
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school, // School Hub icon
                  size: 60,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 10),
                
                Text(
                  'Create Your School Hub Account',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 25),

                // Email
                MyTextfield(
                  hintText: "Email",
                  obscureText: false,
                  controller: emailController,
                  focusNode: null,
                ),
                
                const SizedBox(height: 10),

                // Name
                MyTextfield(
                  hintText: "Full Name",
                  obscureText: false,
                  controller: nameController,
                  focusNode: null,
                ),

                const SizedBox(height: 10),
                
                // ID Number
                MyTextfield(
                  hintText: "Student/Employee ID Number (Optional)",
                  obscureText: false,
                  controller: idNumberController,
                  focusNode: null,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 10),

                // Course/Department
                MyTextfield(
                  hintText: "Course or Department (Optional)",
                  obscureText: false,
                  controller: departmentOrCourseController,
                  focusNode: null,
                ),

                const SizedBox(height: 10),
                
                // Age
                MyTextfield(
                  hintText: "Age (Optional)",
                  obscureText: false,
                  controller: ageController,
                  focusNode: null,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 10),
                
                // Password
                MyTextfield(
                  hintText: "Password",
                  obscureText: true,
                  controller: pwController,
                  focusNode: null,
                ),
                const SizedBox(height: 10),

                // Confirm Password
                MyTextfield(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: confirmPwController,
                  focusNode: null,
                ),
                
                const SizedBox(height: 25),

                // Register Button
                MyButton(
                  text: "Complete Registration",
                  onTap: () => register(context),
                ),

                const SizedBox(height: 25),

                // Switch to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already a Member? ",
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        " Login Now",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}