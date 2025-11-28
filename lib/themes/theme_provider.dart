import 'package:final_project/themes/darkmode.dart';
import 'package:final_project/themes/light_mode.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier{

  ThemeData _themedata = lightModeTheme;

  ThemeData get getThemeData => _themedata;

  bool get isDarkMode => _themedata == darkModeTheme;

  set themeData(ThemeData themeData){
    _themedata = themeData;
    notifyListeners();
  }
  void toggleTheme(){
    if(_themedata == lightModeTheme){
      themeData = darkModeTheme;
    } else {
      themeData = lightModeTheme;
    }
  }
}