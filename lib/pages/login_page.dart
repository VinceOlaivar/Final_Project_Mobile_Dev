import 'package:final_project/components/my_textfield.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
          ),
          
          const SizedBox(height: 10),
          
          MyTextfield(
            hintText: "Password",
            obscureText: true,
          ),

        ],
      )
    );
  }
}