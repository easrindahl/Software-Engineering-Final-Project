import 'package:flutter/material.dart';

import 'test_model_1.dart';

class test_provider_1 extends ChangeNotifier {
  String _test_data_1 = "";
  String get test_data_1 => _test_data_1;

  double _test_data_2 = 0.0;
  double get test_data_2 => _test_data_2;

  test_model_1 _test_model_1 = test_model_1();

  void update_data(String new_data) {
    _test_model_1.calculate(new_data);

    _test_data_1 = _test_model_1.private_data;

    _test_data_2 = _test_model_1.internal_data;

    notifyListeners();
  }
}
