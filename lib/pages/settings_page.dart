import 'package:final_project/themes/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("Settings"), 
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey[800],
        elevation: 0,),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(25),
          padding: const EdgeInsets.all(15),
          child: Row(children: [
            //darkmode
            Text("Dark Mode"),
          
            //switch toggle
             CupertinoSwitch(value: Provider.of<ThemeProvider>(context,listen: false).isDarkMode, 
             onChanged: (value) {
             Provider.of<ThemeProvider>(context,listen: false).toggleTheme();
             },),
          ],),
        )
    );
  }
}