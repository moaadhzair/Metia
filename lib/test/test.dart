import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: OutlinedButton(
          child: const Text('openModalBottomSheet'),
          onPressed: () {
            showModalBottomSheet(
                context: context,
                builder: (ctx) {
                  print('rebuild');
                  return const Text('data');
                });
          },
        ),
      ),
    );
  }
}
