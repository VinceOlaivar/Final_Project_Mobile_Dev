import 'package:final_project/services/auth/auth_service.dart';
import 'package:final_project/components/my_button.dart';
import 'package:final_project/components/my_textfield.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LoginPage extends StatelessWidget {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();

  
  void Function()? onTap;

  LoginPage({super.key, required this.onTap});


//login method
  void login(BuildContext context ) async {

    final authService = AuthService();

    try {
      await authService.signInWithEmailAndPassword( emailController.text, pwController.text);

    }
    catch (e) {
      showDialog(context: context, builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(e.toString()),
      ),
      );
    }

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message, 
              size: 60, 
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            'Welcome to the Login Page',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          MyTextfield(
            hintText: "Email",
            obscureText: false,
            controller: emailController,
            focusNode: null,
          ),
          
          const SizedBox(height: 10),
          
          MyTextfield(
            hintText: "Password",
            obscureText: true,
            controller: pwController,
            focusNode: null
          ),

          const SizedBox(height: 20),

          MyButton(
            text: "Login",
            onTap: () => login(context),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Not a Member? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: onTap,

                child: Text(" Register Now", 
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

        ],
      )
    );
  }
}