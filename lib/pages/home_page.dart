import "package:final_project/auth/auth_service.dart";
import "package:flutter/material.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void logout() {
    // Implement logout functionality here
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Home Page"),
        actions: [
          IconButton(onPressed: logout, icon: Icon(Icons.logout))
        ]
      ),
    );
  }
}