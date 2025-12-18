import 'package:flutter/material.dart';


class ThemeViewModel extends ChangeNotifier {

  ThemeMode theme_mode = ThemeMode.dark;

  bool get is_dark_mode => theme_mode == ThemeMode.dark;


  void toggle_theme(bool is_on) {

  theme_mode = is_on ? ThemeMode.dark : ThemeMode.light;

  notifyListeners();
  }

}
