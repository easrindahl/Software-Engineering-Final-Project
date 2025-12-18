import 'package:flutter/material.dart';

import 'test_model_2.dart';

class test_provider_2 extends ChangeNotifier {
  String _test_data_1 = "";
  String get test_data_1 => _test_data_1;

  double _test_data_2 = 0.0;
  double get test_data_2 => _test_data_2;

  test_model_2 _test_model_2 = test_model_2();

  void calculate(String input) {
    String calculation_concatenate = "data added by test provider 2";

    _test_model_2.calculate(calculation_concatenate, double.parse(input));

    _test_data_1 = _test_model_2.internal_data_1;
    _test_data_2 = _test_model_2.internal_data_2;

    notifyListeners();
  }
}
