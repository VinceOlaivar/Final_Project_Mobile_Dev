import 'package:final_project/services/auth/auth_service.dart';
import 'package:final_project/pages/settings_page.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});


   void logout() {
    // Implement logout functionality here
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(  context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Column(children: [
           //logo
        DrawerHeader(child: Center(
          child: Icon(Icons.message, color: Theme.of(context).colorScheme.primary,
          size: 40),
         ),
      ),

        //home lsit tile
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ListTile(
            title: const Text("H O M E"),
            leading: const Icon(Icons.home),
            onTap: (){
              Navigator.pop(context);
            },
          ),
        ),
        //settings list tile
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: ListTile(
            title: const Text("S E T T I N G S"),
            leading: const Icon(Icons.settings),
            onTap: (){
              Navigator.pop(context);

              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())
              );
            },
            ),
          ),
        ],
        ),
       

        //logute list tile
        Padding(
          padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
          child: ListTile(
            title: Text("L O G O U T"),
            leading: const Icon(Icons.logout),
            onTap: logout,
          ),
        ),


      ],)
    );
  }
}