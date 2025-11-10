// lib/screens/admin_screen.dart
import 'login_screen.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/device_model.dart';
import '../models/permission_log.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
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
                  content: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('🚨 Emergency Stop активирован! Все устройства отключены.'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  duration: Duration(seconds: 3),
                ),
              );
              setState(() {});
            },
            child: Text('Подтвердить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выход',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildUsersTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ==================== ОБЗОР ====================
  Widget _buildOverviewTab() {
    var stats = DeviceService.getDeviceStats();
    int todayChanges = PermissionLogService.getTodayChangesCount();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Controls
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[900]!, Colors.red[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
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
                SizedBox(height: 8),
                Text(
                  'Отключить все устройства экстренно',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _emergencyStop,
                        icon: Icon(Icons.power_settings_new, size: 24),
                        label: Text(
                          'EMERGENCY STOP',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                        icon: Icon(Icons.power, size: 24),
                        label: Text(
                          'ENABLE ALL',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Статистика
          Text(
            'Статистика системы',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Всего устройств',
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
                'Изменений сегодня',
                '$todayChanges',
                Icons.edit,
                Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 24),

          // Быстрый доступ к устройствам
          Text(
            'Устройства',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildDeviceOverview(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
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
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceOverview() {
    return Column(
      children: [
        _buildDeviceRow('📡 Сенсоры', DeviceService.sensors.length, Colors.green),
        _buildDeviceRow('📹 Камера', 1, Colors.blue),
        _buildDeviceRow('💡 LED', DeviceService.leds.length, Colors.orange),
        _buildDeviceRow('🔊 Баззеры', DeviceService.buzzers.length, Colors.purple),
      ],
    );
  }

  Widget _buildDeviceRow(String name, int count, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Text(
            name,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ==================== ПОЛЬЗОВАТЕЛИ ====================
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Управление правами пользователей',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ...users.map((user) => _buildUserCard(user)).toList(),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    String roleName = '';
    Color roleColor = Colors.blue;
    
    switch (user.role) {
      case UserRole.userA:
        roleName = 'User A - Полный доступ';
        roleColor = Colors.blue;
        break;
      case UserRole.userB:
        roleName = 'User B - Сенсоры';
        roleColor = Colors.green;
        break;
      case UserRole.userC:
        roleName = 'User C - Камера и Звук';
        roleColor = Colors.purple;
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
                  backgroundColor: roleColor,
                  radius: 25,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleName,
                          style: TextStyle(
                            fontSize: 12,
                            color: roleColor,
                            fontWeight: FontWeight.w600,
                          ),
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

            _buildPermissionCheckbox(user, 'sensors', '📡 Сенсоры', Colors.green),
            _buildPermissionCheckbox(user, 'camera', '📹 Камера', Colors.blue),
            _buildPermissionCheckbox(user, 'leds', '💡 Светодиоды', Colors.orange),
            _buildPermissionCheckbox(user, 'buzzers', '🔊 Баззеры', Colors.purple),
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
      title: Text(label, style: TextStyle(color: Colors.white)),
      value: user.hasPermission(permission),
      onChanged: (value) {
        setState(() {
          user.updatePermission(permission, value ?? false);
        });

        // Добавляем в лог
        PermissionLogService.addLog(user.username, permission, value ?? false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value == true
                  ? '✅ Доступ к $label предоставлен для ${user.username}'
                  : '❌ Доступ к $label отозван для ${user.username}',
            ),
            duration: Duration(seconds: 2),
            backgroundColor: value == true ? Colors.green[700] : Colors.red[700],
          ),
        );
      },
      activeColor: color,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // ==================== ИСТОРИЯ ====================
  Widget _buildHistoryTab() {
    List<PermissionLog> logs = PermissionLogService.logs;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'История изменений прав',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (logs.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      PermissionLogService.clear();
                    });
                  },
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('Очистить'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey[700]),
                      SizedBox(height: 16),
                      Text(
                        'История пуста',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Изменения прав будут отображаться здесь',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return _buildLogItem(logs[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogItem(PermissionLog log) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: log.granted ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.granted
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              log.granted ? Icons.check : Icons.close,
              color: log.granted ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(
                        text: log.username,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' - '),
                      TextSpan(text: log.getDeviceName()),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Доступ ${log.getActionText()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: log.granted ? Colors.green[300] : Colors.red[300],
                  ),
                ),
              ],
            ),
          ),
          Text(
            log.getFormattedTime(),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

