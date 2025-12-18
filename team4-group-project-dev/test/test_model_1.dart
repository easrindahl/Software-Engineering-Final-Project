/*import 'package:flutter/material.dart';


class test_model with ChangeNotifier {
  
  double _counter = 0;

  double get counter => _counter;


  void incrementCounter() {

    _counter++;

    notifyListeners();

  }
}
*/

import 'dart:math';

class test_model_1 {
  String _private_data = "";
  String get private_data => _private_data;

  double _internal_data = 0.0;
  double get internal_data => _internal_data;

  test_model_1() {
    var random = Random();

    double random_val = random.nextDouble() * 100.0;

    _internal_data = random_val;
  }

  void calculate(String new_data) {
    _private_data = "$new_data concatenated w/ extra model 1 stuff";
  }
}
