// lib/services/connection_service.dart - С BLUETOOTH

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}

class ConnectionService {
  static ConnectionStatus _status = ConnectionStatus.disconnected;
  static String _lastError = '';
  static DateTime? _connectedAt;

  // Bluetooth
  static BluetoothConnection? _connection;
  static BluetoothDevice? _device;
  static final String HC06_NAME = "HC-06"; // Имя вашего HC-06

  // Stream
  static final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  static final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  static Stream<ConnectionStatus> get statusStream => _statusController.stream;
  static Stream<String> get dataStream => _dataController.stream;
  static ConnectionStatus get status => _status;
  static String get lastError => _lastError;
  static DateTime? get connectedAt => _connectedAt;

  // ==================== ПОДКЛЮЧЕНИЕ ====================
  static Future<bool> connect() async {
    _updateStatus(ConnectionStatus.connecting);
    _lastError = '';

    try {
      // Получаем список сопряженных устройств
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      // Ищем HC-06
      _device = devices.firstWhere(
        (device) => device.name == HC06_NAME,
        orElse: () => throw Exception('HC-06 не найден в списке сопряженных устройств'),
      );

      print('Найден: ${_device!.name} (${_device!.address})');

      // Подключаемся
      _connection = await BluetoothConnection.toAddress(_device!.address);
      print('Подключено к ${_device!.name}');

      _updateStatus(ConnectionStatus.connected);
      _connectedAt = DateTime.now();

      // Слушаем данные от Arduino
      _connection!.input!.listen(
        _onDataReceived,
        onDone: () {
          print('Bluetooth отключен');
          _updateStatus(ConnectionStatus.disconnected);
          _connection = null;
        },
        onError: (error) {
          print('Bluetooth ошибка: $error');
          _lastError = error.toString();
          _updateStatus(ConnectionStatus.error);
        },
      );

      // Запрашиваем статус
      await sendCommand('STATUS', '', '');

      return true;
    } catch (e) {
      print('Ошибка подключения: $e');
      _lastError = e.toString();
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  // ==================== ПОЛУЧЕНИЕ ДАННЫХ ====================
  static void _onDataReceived(Uint8List data) {
    String message = utf8.decode(data).trim();
    print('◀ Получено: $message');

    _dataController.add(message);

    // Обработка статуса
    // Формат: STATUS:distance,led,buzzer,servo,alarm,sensor
    if (message.startsWith('STATUS:')) {
      String values = message.substring(7);
      List<String> parts = values.split(',');
      
      if (parts.length >= 6) {
        // Можно обновить DeviceService здесь
        print('Distance: ${parts[0]}cm');
        print('LED: ${parts[1]}');
        print('Buzzer: ${parts[2]}');
        print('Servo: ${parts[3]}°');
        print('Alarm: ${parts[4]}');
        print('Sensor: ${parts[5]}');
      }
    }
  }

  // ==================== ОТПРАВКА КОМАНДЫ ====================
  static Future<bool> sendCommand(String deviceId, String command, dynamic value) async {
    if (_status != ConnectionStatus.connected || _connection == null) {
      print('❌ Не подключено к Arduino');
      return false;
    }

    try {
      String cmd = '';

      // Формируем команду в зависимости от устройства
      switch (deviceId) {
        case 'led1':
        case 'led2':
        case 'led3':
        case 'led4':
          cmd = value == true ? 'LED:ON' : 'LED:OFF';
          break;

        case 'buzz1':
        case 'buzz2':
        case 'buzz3':
          cmd = value == true ? 'BUZZER:ON' : 'BUZZER:OFF';
          break;

        case 'servo1':
          if (command == 'open') {
            cmd = 'SERVO:OPEN';
          } else if (command == 'close') {
            cmd = 'SERVO:CLOSE';
          } else if (command == 'setAngle') {
            cmd = 'SERVO:ANGLE:$value';
          }
          break;

        case 's0':
        case 's1':
        case 's2':
          cmd = value == true ? 'SENSOR:ON' : 'SENSOR:OFF';
          break;

        case 'alarm':
          cmd = value == true ? 'ALARM:ON' : 'ALARM:OFF';
          break;

        default:
          cmd = '$deviceId:$command:$value';
      }

      if (cmd.isNotEmpty) {
        print('▶ Отправка: $cmd');
        _connection!.output.add(Uint8List.fromList(utf8.encode('$cmd\n')));
        await _connection!.output.allSent;
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Ошибка отправки: $e');
      _lastError = e.toString();
      return false;
    }
  }

  // ==================== ОТКЛЮЧЕНИЕ ====================
  static Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.finish();
      _connection = null;
    }
    _updateStatus(ConnectionStatus.disconnected);
    _connectedAt = null;
    print('🔌 Отключено от Arduino');
  }

  // ==================== ПЕРЕПОДКЛЮЧЕНИЕ ====================
  static Future<bool> reconnect() async {
    await disconnect();
    await Future.delayed(Duration(milliseconds: 500));
    return await connect();
  }

  // ==================== PING ====================
  static Future<int> ping() async {
    if (_status != ConnectionStatus.connected) {
      return -1;
    }

    int startTime = DateTime.now().millisecondsSinceEpoch;
    await sendCommand('STATUS', '', '');
    int endTime = DateTime.now().millisecondsSinceEpoch;
    
    return endTime - startTime;
  }

  // ==================== ПОИСК HC-06 ====================
  static Future<List<BluetoothDevice>> findDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print('Ошибка поиска устройств: $e');
      return [];
    }
  }

  // ==================== ОБНОВЛЕНИЕ СТАТУСА ====================
  static void _updateStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  // ==================== ПОЛУЧЕНИЕ СТАТУСА ====================
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

  static String getConnectionDuration() {
    if (_connectedAt == null) return '0:00';
    
    Duration duration = DateTime.now().difference(_connectedAt!);
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static void dispose() {
    _statusController.close();
    _dataController.close();
    disconnect();
  }
}