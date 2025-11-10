import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(SmartHomeApp());
}

class SmartHomeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home Security',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}