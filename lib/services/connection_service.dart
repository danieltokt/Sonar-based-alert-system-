// lib/services/connection_service.dart - ОБНОВЛЕННЫЙ С ИНТЕГРАЦИЕЙ DEVICE_MODEL

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/device_model.dart';

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
  static final String HC06_NAME = "HC-06";

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
      // Включаем Bluetooth если выключен
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == false) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      // Получаем список сопряженных устройств
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      
      print('Найдено устройств: ${devices.length}');
      for (var d in devices) {
        print('- ${d.name} (${d.address})');
      }

      // Ищем HC-06
      _device = devices.firstWhere(
        (device) => device.name == HC06_NAME,
        orElse: () => throw Exception('HC-06 не найден. Убедитесь что он сопряжен!'),
      );

      print('✓ Найден: ${_device!.name} (${_device!.address})');

      // Подключаемся
      _connection = await BluetoothConnection.toAddress(_device!.address);
      print('✓ Подключено к ${_device!.name}');

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

      // Ждем немного и запрашиваем статус
      await Future.delayed(Duration(milliseconds: 500));
      await sendCommand('STATUS', '', '');

      return true;
    } catch (e) {
      print('❌ Ошибка подключения: $e');
      _lastError = e.toString();
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  // ==================== ПОЛУЧЕНИЕ ДАННЫХ ====================
  static void _onDataReceived(Uint8List data) {
    String message = utf8.decode(data).trim();
    if (message.isEmpty) return;
    
    print('◀ Получено: $message');
    _dataController.add(message);

    // Парсим STATUS
    // Формат: STATUS:d0,d1,d2,led,buzzer,servo,alarm,sensor
    if (message.startsWith('STATUS:')) {
      try {
        String values = message.substring(7);
        List<String> parts = values.split(',');
        
        if (parts.length >= 8) {
          // Обновляем сенсоры
          if (parts[0] != '999') DeviceService.sensors[0].distance = double.parse(parts[0]);
          if (parts[1] != '999') DeviceService.sensors[1].distance = double.parse(parts[1]);
          if (parts[2] != '999') DeviceService.sensors[2].distance = double.parse(parts[2]);
          
          // LED
          bool ledOn = parts[3] == '1';
          for (var led in DeviceService.leds) {
            led.isEnabled = ledOn;
          }
          
          // Buzzer
          bool buzzerOn = parts[4] == '1';
          for (var buzzer in DeviceService.buzzers) {
            buzzer.isEnabled = buzzerOn;
          }
          
          // Servo
          int servoAngle = int.parse(parts[5]);
          DeviceService.servo.angle = servoAngle;
          DeviceService.servo.isDoorClosed = (servoAngle == 90);
          
          // Alarm
          DeviceService.isAlarmActive = parts[6] == '1';
          
          // Sensor armed
          bool sensorArmed = parts[7] == '1';
          for (var sensor in DeviceService.sensors) {
            sensor.isEnabled = sensorArmed;
          }
          
          print('✓ Статус обновлен');
        }
      } catch (e) {
        print('Ошибка парсинга STATUS: $e');
      }
    }
    
    // Обработка других сообщений
    else if (message.startsWith('MOTION:')) {
      print('🚨 Движение обнаружено!');
    } else if (message.contains('ALARM:ACTIVATED')) {
      DeviceService.isAlarmActive = true;
      print('🚨 ТРЕВОГА АКТИВИРОВАНА');
    } else if (message.contains('ALARM:DEACTIVATED')) {
      DeviceService.isAlarmActive = false;
      print('✓ Тревога деактивирована');
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

      // Формируем команду
      if (deviceId == 'led1') {
        cmd = 'LED1:${value == true ? "ON" : "OFF"}';
      } else if (deviceId == 'led2') {
        cmd = 'LED2:${value == true ? "ON" : "OFF"}';
      } else if (deviceId == 'led3') {
        cmd = 'LED3:${value == true ? "ON" : "OFF"}';
      } else if (deviceId == 'led4') {
        cmd = 'LED4:${value == true ? "ON" : "OFF"}';
      } else if (deviceId.startsWith('buzz')) {
        cmd = '${deviceId.toUpperCase()}:${value == true ? "ON" : "OFF"}';
      } else if (deviceId == 'servo1') {
        if (command == 'open') {
          cmd = 'SERVO:OPEN';
        } else if (command == 'close') {
          cmd = 'SERVO:CLOSE';
        } else if (command == 'setAngle') {
          cmd = 'SERVO:ANGLE:$value';
        }
      } else if (deviceId.startsWith('s')) {
        // Sensor
        cmd = 'SENSOR:${value == true ? "ON" : "OFF"}';
      } else if (deviceId == 'alarm') {
        cmd = 'ALARM:${value == true ? "ON" : "OFF"}';
      } else if (deviceId == 'STATUS') {
        cmd = 'STATUS';
      }

      if (cmd.isNotEmpty) {
        print('▶ Отправка: $cmd');
        _connection!.output.add(Uint8List.fromList(utf8.encode('$cmd\n')));
        await _connection!.output.allSent;
        
        // Ждем ответ
        await Future.delayed(Duration(milliseconds: 100));
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

  // ==================== ПОИСК УСТРОЙСТВ ====================
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

  // ==================== СТАТУС В СТРОКУ ====================
  static String getStatusText() {
    switch (_status) {
      case ConnectionStatus.connected:
        return 'Подключено';
      case ConnectionStatus.connecting:
        return 'Подключение...';
      case ConnectionStatus.disconnected:
        return 'Отключено';
      case ConnectionStatus.error:
        return 'Ошибка';
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