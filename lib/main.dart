// lib/main.dart - FINAL VERSION WITH SECRET ADMIN LOGIN

import 'package:flutter/material.dart';
import 'dart:async';
import 'models/user_model.dart';
import 'models/device_model.dart';
import 'models/permission_log.dart';
import 'services/connection_service.dart';
import 'widgets/sensor_card.dart';
import 'widgets/servo_widget.dart';
import 'widgets/alarm_panel.dart';
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
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 120, color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Smart Home Security',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 40),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;
  late AnimationController _shakeController;

  // Для секретного входа админа
  int _logoTapCount = 0;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  // Секретный вход админа - нажать 5 раз на логотип
  void _onLogoTap() {
    setState(() {
      _logoTapCount++;
    });

    // Сброс счетчика через 3 секунды
    _resetTimer?.cancel();
    _resetTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _logoTapCount = 0;
        });
      }
    });

    // Вход в админку при 5 нажатиях
    if (_logoTapCount >= 5) {
      _openAdminLogin();
    }
  }

  void _openAdminLogin() {
    showDialog(context: context, builder: (context) => AdminLoginDialog());

    // Сброс счетчика
    setState(() {
      _logoTapCount = 0;
    });
    _resetTimer?.cancel();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.delayed(Duration(milliseconds: 500));

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    // Запрещаем вход через обычную форму для админа
    if (username.toLowerCase() == 'admin') {
      _shake();
      setState(() {
        _errorMessage = 'Используйте секретный вход для администратора';
        _isLoading = false;
      });
      return;
    }

    UserModel? user = AuthService.login(username, password);

    if (user != null && user.role != UserRole.admin) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DashboardScreen(user: user),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      _shake();
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
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset =
                    10 * _shakeController.value * (1 - _shakeController.value);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип с секретным входом
                  GestureDetector(
                    onTap: _onLogoTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Hero(
                          tag: 'app_icon',
                          child: Icon(
                            Icons.security,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                        // Индикатор нажатий (скрытый до первого нажатия)
                        if (_logoTapCount > 0)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$_logoTapCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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

                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red[300]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'ВОЙТИ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 18,
                      ),
                      backgroundColor: Colors.blue[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  // Подсказка (скрытая)
                  SizedBox(height: 40),
                  Opacity(
                    opacity: 0.3,
                    child: Text(
                      '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ДИАЛОГ ВХОДА АДМИНА ====================
class AdminLoginDialog extends StatefulWidget {
  @override
  _AdminLoginDialogState createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog> {
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  void _adminLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await Future.delayed(Duration(milliseconds: 500));

    String password = _passwordController.text.trim();

    // Проверяем пароль админа
    if (password == 'admin123') {
      UserModel? admin = AuthService.login('admin', 'admin123');

      if (admin != null) {
        Navigator.pop(context); // Закрываем диалог
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AdminScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Неверный пароль администратора';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Access',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Введите пароль администратора',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Поле пароля
            TextField(
              controller: _passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.lock, color: Colors.red),
                filled: true,
                fillColor: Colors.grey[850],
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (_) => _adminLogin(),
            ),

            // Ошибка
            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[300], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24),

            // Кнопки
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Отмена'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _adminLogin,
                    child: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text('ВОЙТИ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
                    ConnectionStatusWidget(),
                    SizedBox(height: 20),
                    _buildDeviceStats(),
                    SizedBox(height: 20),

                    if (widget.user.hasPermission('sensors')) ...[
                      _buildSectionTitle('📡 Сенсоры'),
                      SizedBox(height: 12),
                      ...DeviceService.sensors.map((sensor) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: SensorCard(
                            sensor: sensor,
                            onToggle: (value) => setState(() {}),
                          ),
                        );
                      }).toList(),
                    ],

                    if (widget.user.hasPermission('servo')) ...[
                      _buildSectionTitle('🚪 Управление дверью'),
                      SizedBox(height: 12),
                      ServoWidget(
                        servo: DeviceService.servo,
                        onAngleChange: (angle) => setState(() {}),
                        onDoorToggle: (closed) => setState(() {}),
                      ),
                      SizedBox(height: 20),
                    ],

                    if (widget.user.hasPermission('leds')) ...[
                      _buildSectionTitle('💡 Светодиоды'),
                      SizedBox(height: 12),
                      LEDControl(
                        leds: DeviceService.leds,
                        onToggle: (id, value) => setState(() {}),
                      ),
                      SizedBox(height: 20),
                    ],

                    if (widget.user.hasPermission('buzzers')) ...[
                      _buildSectionTitle('🔊 Звуковая сигнализация'),
                      SizedBox(height: 12),
                      BuzzerControl(
                        buzzers: DeviceService.buzzers,
                        onToggle: (id, value) => setState(() {}),
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }
}

// ==================== ADMIN SCREEN ====================
class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> users = AuthService.getAllUsers();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Emergency Stop'),
          ],
        ),
        content: Text(
          'Вы уверены? Это отключит все устройства кроме камеры!\n\nКамера продолжит работать для безопасности.',
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
                  backgroundColor: Colors.red[700],
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Обзор'),
            Tab(icon: Icon(Icons.people), text: 'Пользователи'),
            Tab(icon: Icon(Icons.history), text: 'История'),
          ],
        ),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildUsersTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    var stats = DeviceService.getDeviceStats();
    int todayChanges = PermissionLogService.getTodayChangesCount();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[900]!, Colors.red[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.warning_amber, size: 60, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Emergency Controls',
                  style: TextStyle(
                    fontSize: 22,
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
                        icon: Icon(Icons.power_settings_new),
                        label: Text('STOP'),
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
                        },
                        icon: Icon(Icons.power),
                        label: Text('ENABLE'),
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
          SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard(
                'Всего',
                '${stats['total']}',
                Icons.devices,
                Colors.blue,
              ),
              _buildStatCard(
                'Онлайн',
                '${stats['online']}',
                Icons.wifi,
                Colors.green,
              ),
              _buildStatCard(
                'Активных',
                '${stats['enabled']}',
                Icons.power,
                Colors.orange,
              ),
              _buildStatCard(
                'Изменений',
                '$todayChanges',
                Icons.edit,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: users.map((user) => _buildUserCard(user)).toList(),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(user.username[0].toUpperCase()),
                  backgroundColor: Colors.blue,
                ),
                SizedBox(width: 12),
                Text(
                  user.username,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(),
            CheckboxListTile(
              title: Text('📡 Сенсоры'),
              value: user.hasPermission('sensors'),
              onChanged: (v) {
                setState(() => user.updatePermission('sensors', v!));
                PermissionLogService.addLog(user.username, 'sensors', v!);
              },
            ),
            CheckboxListTile(
              title: Text('🚪 Серво (Дверь)'),
              value: user.hasPermission('servo'),
              onChanged: (v) {
                setState(() => user.updatePermission('servo', v!));
                PermissionLogService.addLog(user.username, 'servo', v!);
              },
            ),
            CheckboxListTile(
              title: Text('💡 LED'),
              value: user.hasPermission('leds'),
              onChanged: (v) {
                setState(() => user.updatePermission('leds', v!));
                PermissionLogService.addLog(user.username, 'leds', v!);
              },
            ),
            CheckboxListTile(
              title: Text('🔊 Баззеры'),
              value: user.hasPermission('buzzers'),
              onChanged: (v) {
                setState(() => user.updatePermission('buzzers', v!));
                PermissionLogService.addLog(user.username, 'buzzers', v!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    List<PermissionLog> logs = PermissionLogService.logs;
    return logs.isEmpty
        ? Center(child: Text('История пуста'))
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (c, i) {
              var log = logs[i];
              return Card(
                child: ListTile(
                  leading: Icon(
                    log.granted ? Icons.check : Icons.close,
                    color: log.granted ? Colors.green : Colors.red,
                  ),
                  title: Text('${log.username} - ${log.getDeviceName()}'),
                  subtitle: Text('Доступ ${log.getActionText()}'),
                  trailing: Text(
                    log.getFormattedTime(),
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              );
            },
          );
  }
}
