import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'test_provider_1.dart';

class test_view_1 extends StatefulWidget {
  const test_view_1({super.key, required this.title});

  final String title;

  @override
  State<test_view_1> createState() => test_view_1_state();
}

class test_view_1_state extends State<test_view_1> {
  final TextEditingController _inputItemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<test_provider_1>(
      builder: (context, provider_state, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _inputItemController,
                decoration: InputDecoration(
                  labelText: "input data: ",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  String input_data = _inputItemController.text;

                  final state_test_provider_1 = context.read<test_provider_1>();

                  state_test_provider_1.update_data(input_data);
                },
                child: const Text('do something'),
              ),

              SizedBox(height: 20),

              const Text('test_data_1 from provider/model 1: '),

              Text(
                provider_state.test_data_1,
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              SizedBox(height: 20),

              const Text('test_data_2 from provider/model 1: '),

              Text(
                provider_state.test_data_2.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
