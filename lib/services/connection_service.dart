// lib/services/connection_service.dart

import 'dart:async';
import 'dart:math';

// ==================== СТАТУС ПОДКЛЮЧЕНИЯ ====================
enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}

// ==================== СЕРВИС ПОДКЛЮЧЕНИЯ ====================
class ConnectionService {
  static ConnectionStatus _status = ConnectionStatus.disconnected;
  static String _lastError = '';
  static DateTime? _connectedAt;
  static final Random _random = Random();

  // Stream для отслеживания статуса подключения
  static final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();

  static Stream<ConnectionStatus> get statusStream => _statusController.stream;
  static ConnectionStatus get status => _status;
  static String get lastError => _lastError;
  static DateTime? get connectedAt => _connectedAt;

  // Получить время подключения в формате строки
  static String getConnectionDuration() {
    if (_connectedAt == null) return '0:00';
    
    Duration duration = DateTime.now().difference(_connectedAt!);
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ==================== ПОДКЛЮЧЕНИЕ К ARDUINO ====================
  static Future<bool> connect() async {
    _updateStatus(ConnectionStatus.connecting);
    _lastError = '';

    // Имитация задержки подключения (реалистичная задержка сети)
    await Future.delayed(Duration(seconds: 2));

    // Имитация случайного успеха/неудачи (95% успех)
    bool success = _random.nextInt(100) < 95;

    if (success) {
      _updateStatus(ConnectionStatus.connected);
      _connectedAt = DateTime.now();
      print('✅ Connected to Arduino successfully');
      return true;
    } else {
      _updateStatus(ConnectionStatus.error);
      _lastError = 'Connection timeout. Check Arduino device.';
      print('❌ Failed to connect to Arduino');
      return false;
    }
  }

  // ==================== ОТКЛЮЧЕНИЕ ====================
  static Future<void> disconnect() async {
    _updateStatus(ConnectionStatus.disconnected);
    _connectedAt = null;
    await Future.delayed(Duration(milliseconds: 500));
    print('🔌 Disconnected from Arduino');
  }

  // ==================== ПЕРЕПОДКЛЮЧЕНИЕ ====================
  static Future<bool> reconnect() async {
    await disconnect();
    await Future.delayed(Duration(milliseconds: 500));
    return await connect();
  }

  // ==================== ОТПРАВКА КОМАНДЫ НА ARDUINO ====================
  static Future<bool> sendCommand(String deviceId, String command, dynamic value) async {
    if (_status != ConnectionStatus.connected) {
      print('❌ Cannot send command: not connected');
      return false;
    }

    // Имитация задержки отправки команды
    await Future.delayed(Duration(milliseconds: 100 + _random.nextInt(200)));

    // Имитация случайной ошибки (2% шанс)
    bool success = _random.nextInt(100) > 2;

    if (success) {
      print('📤 Command sent: $deviceId -> $command = $value');
      return true;
    } else {
      print('❌ Failed to send command');
      _lastError = 'Command failed. Network error.';
      return false;
    }
  }

  // ==================== ПОЛУЧЕНИЕ ДАННЫХ С ARDUINO ====================
  static Future<Map<String, dynamic>?> getData() async {
    if (_status != ConnectionStatus.connected) {
      return null;
    }

    // Имитация задержки получения данных
    await Future.delayed(Duration(milliseconds: 50));

    // Возвращаем симулированные данные
    return {
      'sensors': {
        's0': {'distance': 15.0 + _random.nextDouble() * 5, 'status': 'online'},
        's1': {'distance': 20.0 + _random.nextDouble() * 5, 'status': 'online'},
        's2': {'distance': 10.0 + _random.nextDouble() * 5, 'status': 'online'},
      },
      'camera': {'status': 'online', 'recording': false, 'angle': 90},
      'leds': {
        'led1': {'status': 'online', 'enabled': false},
        'led2': {'status': 'online', 'enabled': false},
        'led3': {'status': 'online', 'enabled': false},
        'led4': {'status': 'online', 'enabled': false},
      },
      'buzzers': {
        'buzz1': {'status': 'online', 'enabled': false},
        'buzz2': {'status': 'online', 'enabled': false},
        'buzz3': {'status': 'online', 'enabled': false},
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ==================== ПРОВЕРКА СВЯЗИ (PING) ====================
  static Future<int> ping() async {
    if (_status != ConnectionStatus.connected) {
      return -1;
    }

    int startTime = DateTime.now().millisecondsSinceEpoch;
    
    // Имитация задержки пинга (20-100ms)
    await Future.delayed(Duration(milliseconds: 20 + _random.nextInt(80)));
    
    int endTime = DateTime.now().millisecondsSinceEpoch;
    int latency = endTime - startTime;
    
    return latency;
  }

  // ==================== АВТОМАТИЧЕСКОЕ ПЕРЕПОДКЛЮЧЕНИЕ ====================
  static void startAutoReconnect() {
    Timer.periodic(Duration(seconds: 10), (timer) async {
      if (_status == ConnectionStatus.disconnected || 
          _status == ConnectionStatus.error) {
        print('🔄 Auto-reconnecting...');
        await reconnect();
      }
    });
  }

  // ==================== ОБНОВЛЕНИЕ СТАТУСА ====================
  static void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  // ==================== ПОЛУЧЕНИЕ СТАТУСА В ВИДЕ ТЕКСТА ====================
  static String getStatusText() {
    switch (_status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  // ==================== ПОЛУЧЕНИЕ ЦВЕТА СТАТУСА ====================
  static String getStatusColor() {
    switch (_status) {
      case ConnectionStatus.connected:
        return 'green';
      case ConnectionStatus.connecting:
        return 'orange';
      case ConnectionStatus.disconnected:
        return 'grey';
      case ConnectionStatus.error:
        return 'red';
    }
  }

  // Закрыть stream при завершении приложения
  static void dispose() {
    _statusController.close();
  }
}