class test_model_2
{
  String _internal_data_1 = "";
  String get internal_data_1 => _internal_data_1;

  double _internal_data_2 = 0.0;
  double get internal_data_2 => _internal_data_2;

  test_model_2() {}

  void calculate(String input_from_provider, double input_from_view)
  {
    _internal_data_1 = "$input_from_provider, data added by test model 2.";

    _internal_data_2 = input_from_view * 3.14159 + 77.0;
  }
}