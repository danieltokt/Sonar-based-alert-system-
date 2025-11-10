import 'package:flutter/material.dart';

class UserAScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User A - Полный доступ'),
      ),
      body: Center(
        child: Text(
          'Экран User A\n(Все устройства)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}