import 'package:flutter/material.dart';

import 'test_view_1.dart';
import 'test_view_2.dart';

class test_view_route extends StatelessWidget {
  const test_view_route({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('basic navigation page')),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const test_view_1(title: 'test view 1'),
                  ),
                );
              },
              child: const Text('-> view 1'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const test_view_2(title: 'test view 2'),
                  ),
                );
              },
              child: const Text('-> view 2'),
            ),
          ],
        ),
      ),
    );
  }
}
