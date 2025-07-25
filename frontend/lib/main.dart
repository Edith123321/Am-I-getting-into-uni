import 'package:flutter/material.dart';
import 'screens/prediction_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What Are My Chances of getting into Grad school?',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PredictionScreen(),
    );
  }
}