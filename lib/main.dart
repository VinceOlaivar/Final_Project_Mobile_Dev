import 'package:final_project/auth/login_or_register.dart';
import 'package:final_project/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:final_project/themes/ligh_mode.dart';
import 'package:final_project/pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginOrRegister(),
      theme: lightModeTheme,
    );
  }
}    