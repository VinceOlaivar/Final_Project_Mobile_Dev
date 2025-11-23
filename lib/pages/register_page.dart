import 'package:final_project/components/my_button.dart';
import 'package:final_project/components/my_textfield.dart';
import 'package:flutter/material.dart';

class RegisterPage  extends StatelessWidget {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  final void Function()? onTap;

  RegisterPage ({super.key, required this.onTap});

  //register method
  void register(){} 

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
            'Lets get you registered',
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
          ),
          
          const SizedBox(height: 10),
          
          MyTextfield(
            hintText: "Password",
            obscureText: true,
            controller: confirmPwController,
          ),
         
          const SizedBox(height: 10),
          
          MyTextfield(
            hintText: "Confirm Password",
            obscureText: true,
            controller: pwController,
          ),
          
          const SizedBox(height: 20),

          MyButton(
            text: "Register",
            onTap: register,
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already a Member? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(" Login Now", 
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