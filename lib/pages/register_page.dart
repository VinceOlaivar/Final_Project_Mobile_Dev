import 'package:final_project/services/auth/auth_service.dart';
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
  void register(BuildContext context) async {
    final auth = AuthService();
    
    //check if passwords match
    if (pwController.text == confirmPwController.text){
      try {
        auth.signUpWithEmailAndPassword(emailController.text, pwController.text);

      }catch (e) {
        showDialog(context: context, builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(e.toString()),
        ),
       );
      }
    }
    //passwords do not match
    else {
      showDialog(context: context, builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text("Passwords do not match"),
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
            focusNode: null
          ),
          
          const SizedBox(height: 10),
          
          MyTextfield(
            hintText: "Password",
            obscureText: true,
            controller: confirmPwController,
            focusNode: null,
          ),
         
          const SizedBox(height: 10),
          
          MyTextfield(
            hintText: "Confirm Password",
            obscureText: true,
            controller: pwController,
            focusNode: null,
          ),
          
          const SizedBox(height: 20),

          MyButton(
            text: "Register",
            onTap: () => register(context),
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