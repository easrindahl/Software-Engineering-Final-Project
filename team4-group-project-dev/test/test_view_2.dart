import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:flutter/services.dart';

import 'test_provider_2.dart';

class test_view_2 extends StatefulWidget {
  const test_view_2({super.key, required this.title});

  final String title;

  @override
  State<test_view_2> createState() => test_view_2_state();
}

class test_view_2_state extends State<test_view_2> {
  final TextEditingController _inputItemController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                labelText: "input data (num only): ",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),

            SizedBox(height: 10),

            Consumer<test_provider_2>(
              builder: (context, provider_state, child) => Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      String input_data = _inputItemController.text;

                      final state_test_provider_2 = context
                          .read<test_provider_2>();

                      state_test_provider_2.calculate(input_data);
                    },

                    child: const Text('do something'),
                  ),

                  SizedBox(height: 10),

                  const Text('test_data_1 from provider/model 2: '),

                  Text(
                    provider_state.test_data_1,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  SizedBox(height: 10),

                  const Text('test_data_2 from provider/model 2: '),

                  Text(
                    provider_state.test_data_2.toString(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
