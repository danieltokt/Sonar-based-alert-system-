import 'package:flutter/material.dart';
import 'user_a_screen.dart';
import 'user_b_screen.dart';
import 'user_c_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  // Hardcoded пользователи
  final Map<String, Map<String, dynamic>> _users = {
    'userA': {'password': 'pass123', 'screen': UserAScreen()},
    'userB': {'password': 'pass123', 'screen': UserBScreen()},
    'userC': {'password': 'pass123', 'screen': UserCScreen()},
    'admin': {'password': 'admin123', 'screen': AdminScreen()},
  };

  void _login() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (_users.containsKey(username)) {
      if (_users[username]!['password'] == password) {
        // Успешный вход
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => _users[username]!['screen']),
        );
      } else {
        setState(() {
          _errorMessage = 'Неверный пароль';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Пользователь не найден';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              Text(
                'Smart Home Security',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 50),
              
              // Поле Username
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              
              // Поле Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              
              // Сообщение об ошибке
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              
              // Кнопка входа
              ElevatedButton(
                onPressed: _login,
                child: Text(
                  'ВОЙТИ',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}