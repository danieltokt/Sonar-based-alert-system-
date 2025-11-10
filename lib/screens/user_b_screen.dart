import 'package:flutter/material.dart';

class UserBScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User B - Сенсоры'),
      ),
      body: Center(
        child: Text(
          'Экран User B\n(Только сенсоры)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}