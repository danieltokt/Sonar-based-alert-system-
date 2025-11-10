import 'package:flutter/material.dart';

class UserCScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User C - Камера и Звук'),
      ),
      body: Center(
        child: Text(
          'Экран User C\n(Камера + Звук)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}