// lib/main.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'models/user_model.dart';
import 'models/device_model.dart';
import 'services/connection_service.dart';
import 'widgets/sensor_card.dart';
import 'widgets/camera_widget.dart';
import 'widgets/led_control.dart';
import 'widgets/buzzer_control.dart';
import 'widgets/connection_status.dart';

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
        scaffoldBackgroundColor: Color(0xFF121212),
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Имитация задержки сети
    await Future.delayed(Duration(milliseconds: 500));

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    UserModel? user = AuthService.login(username, password);

    if (user != null) {
      // Успешный вход - переход на соответствующий экран
      Widget screen;
      
      switch (user.role) {
        case UserRole.userA:
        case UserRole.userB:
        case UserRole.userC:
          screen = DashboardScreen(user: user);
          break;
        case UserRole.admin:
          screen = AdminScreen();
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      setState(() {
        _errorMessage = 'Неверный логин или пароль';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 100,
                  color: Colors.white,
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
                
                // Username field
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.person),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 20),
                
                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: TextStyle(color: Colors.white),
                  onSubmitted: (_) => _login(),
                ),
                SizedBox(height: 10),
                
                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                SizedBox(height: 20),
                
                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'ВОЙТИ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== DASHBOARD SCREEN ====================
class DashboardScreen extends StatefulWidget {
  final UserModel user;

  DashboardScreen({required this.user});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    setState(() {
      _isConnecting = true;
    });

    await ConnectionService.connect();

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  String _getRoleTitle() {
    switch (widget.user.role) {
      case UserRole.userA:
        return 'User A - Полный доступ';
      case UserRole.userB:
        return 'User B - Сенсоры';
      case UserRole.userC:
        return 'User C - Камера и Звук';
      default:
        return 'User';
    }
  }

  void _logout() {
    ConnectionService.disconnect();
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getRoleTitle()),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выход',
          ),
        ],
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Подключение к Arduino...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ConnectionService.reconnect();
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статус подключения
                    ConnectionStatusWidget(),
                    SizedBox(height: 20),

                    // Статистика устройств
                    _buildDeviceStats(),
                    SizedBox(height: 20),

                    // Сенсоры
                    if (widget.user.hasPermission('sensors')) ...[
                      _buildSectionTitle('📡 Сенсоры'),
                      SizedBox(height: 12),
                      ...DeviceService.sensors.map((sensor) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: SensorCard(
                            sensor: sensor,
                            onToggle: (value) {
                              setState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ],

                    // Камера
                    if (widget.user.hasPermission('camera')) ...[
                      _buildSectionTitle('📹 Камера'),
                      SizedBox(height: 12),
                      CameraWidget(
                        camera: DeviceService.camera,
                        onRecordingToggle: (isRecording) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 20),
                    ],

                    // LED
                    if (widget.user.hasPermission('leds')) ...[
                      _buildSectionTitle('💡 Светодиоды'),
                      SizedBox(height: 12),
                      LEDControl(
                        leds: DeviceService.leds,
                        onToggle: (id, value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 20),
                    ],

                    // Баззеры
                    if (widget.user.hasPermission('buzzers')) ...[
                      _buildSectionTitle('🔊 Звуковая сигнализация'),
                      SizedBox(height: 12),
                      BuzzerControl(
                        buzzers: DeviceService.buzzers,
                        onToggle: (id, value) {
                          setState(() {});
                        },
                      ),
                    ],

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildDeviceStats() {
    var stats = DeviceService.getDeviceStats();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, Colors.blue[700]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Всего', '${stats['total']}', Icons.devices),
          _buildStatItem('Онлайн', '${stats['online']}', Icons.wifi),
          _buildStatItem('Активно', '${stats['enabled']}', Icons.power),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ==================== ADMIN SCREEN ====================
class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<UserModel> users = AuthService.getAllUsers();

  void _logout() {
    AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _emergencyStop() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Emergency Stop'),
          ],
        ),
        content: Text(
          'Вы уверены? Это отключит все устройства кроме камеры!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              DeviceService.emergencyStop();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🚨 Emergency Stop активирован!'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {});
            },
            child: Text('Подтвердить'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel'),
        backgroundColor: Colors.red[700],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выход',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Stop
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_amber, size: 50, color: Colors.red),
                  SizedBox(height: 12),
                  Text(
                    'Emergency Controls',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _emergencyStop,
                          icon: Icon(Icons.power_off),
                          label: Text('EMERGENCY STOP'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            DeviceService.enableAll();
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Все устройства включены'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: Icon(Icons.power),
                          label: Text('ENABLE ALL'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Управление правами пользователей
            Text(
              'Управление правами пользователей',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),

            // Список пользователей
            ...users.map((user) => _buildUserCard(user)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    String roleName = '';
    switch (user.role) {
      case UserRole.userA:
        roleName = 'User A - Полный доступ';
        break;
      case UserRole.userB:
        roleName = 'User B - Сенсоры';
        break;
      case UserRole.userC:
        roleName = 'User C - Камера и Звук';
        break;
      default:
        roleName = 'User';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        roleName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: Colors.grey[700]),
            SizedBox(height: 12),
            Text(
              'Права доступа:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            SizedBox(height: 12),

            // Чекбоксы прав
            _buildPermissionCheckbox(
              user,
              'sensors',
              '📡 Сенсоры',
              Colors.green,
            ),
            _buildPermissionCheckbox(
              user,
              'camera',
              '📹 Камера',
              Colors.blue,
            ),
            _buildPermissionCheckbox(
              user,
              'leds',
              '💡 Светодиоды',
              Colors.orange,
            ),
            _buildPermissionCheckbox(
              user,
              'buzzers',
              '🔊 Баззеры',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCheckbox(
    UserModel user,
    String permission,
    String label,
    Color color,
  ) {
    return CheckboxListTile(
      title: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
      value: user.hasPermission(permission),
      onChanged: (value) {
        setState(() {
          user.updatePermission(permission, value ?? false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value == true
                  ? '✅ Доступ к $label предоставлен для ${user.username}'
                  : '❌ Доступ к $label отозван для ${user.username}',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
      activeColor: color,
      contentPadding: EdgeInsets.zero,
    );
  }
}