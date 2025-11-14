// lib/models/device_model.dart - ОБНОВЛЕННАЯ ВЕРСИЯ

import 'package:flutter/material.dart';

// ==================== БАЗОВЫЙ КЛАСС УСТРОЙСТВА ====================
abstract class Device {
  final String id;
  final String name;
  bool isEnabled;
  DeviceStatus status;

  Device({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.status = DeviceStatus.online,
  });

  void toggle() {
    isEnabled = !isEnabled;
  }
}

// ==================== СТАТУСЫ УСТРОЙСТВ ====================
enum DeviceStatus {
  online,
  offline,
  error,
  warning,
}

// ==================== СЕНСОР ====================
class SensorDevice extends Device {
  double distance;
  final double maxDistance;
  final double minDistance;
  final double alarmThreshold; // Порог срабатывания тревоги

  SensorDevice({
    required String id,
    required String name,
    required this.distance,
    this.maxDistance = 50.0,
    this.minDistance = 0.0,
    this.alarmThreshold = 20.0, // По умолчанию 20см
    bool isEnabled = true,
  }) : super(
          id: id,
          name: name,
          isEnabled: isEnabled,
          status: DeviceStatus.online,
        );

  bool isAlarmTriggered() {
    return isEnabled && distance < alarmThreshold;
  }

  Color getIndicatorColor() {
    if (!isEnabled) return Colors.grey;
    
    if (distance < alarmThreshold) {
      return Colors.red; // ТРЕВОГА!
    } else if (distance < 30) {
      return Colors.orange; // Близко
    } else {
      return Colors.green; // Норма
    }
  }

  String getStatusText() {
    if (!isEnabled) return 'Выключен';
    
    if (distance < alarmThreshold) {
      return '🚨 ТРЕВОГА';
    } else if (distance < 30) {
      return 'Внимание';
    } else {
      return 'Норма';
    }
  }
}

// ==================== СЕРВО МОТОР (ДВЕРЬ) ====================
class ServoDevice extends Device {
  int angle; // Текущий угол (0-180)
  bool isDoorClosed; // Дверь закрыта?
  final int openAngle; // Угол открытой двери
  final int closedAngle; // Угол закрытой двери

  ServoDevice({
    required String id,
    required String name,
    this.angle = 0,
    this.isDoorClosed = false,
    this.openAngle = 0,
    this.closedAngle = 90,
  }) : super(
          id: id,
          name: name,
          isEnabled: true, // Серво всегда готов к работе
          status: DeviceStatus.online,
        );

  // Закрыть дверь
  void closeDoor() {
    angle = closedAngle;
    isDoorClosed = true;
  }

  // Открыть дверь
  void openDoor() {
    angle = openAngle;
    isDoorClosed = false;
  }

  // Установить произвольный угол
  void setAngle(int newAngle) {
    if (newAngle >= 0 && newAngle <= 180) {
      angle = newAngle;
      isDoorClosed = (angle == closedAngle);
    }
  }

  String getDoorStatus() {
    if (isDoorClosed) {
      return '🔒 Закрыта';
    } else {
      return '🔓 Открыта';
    }
  }
}

// ==================== СВЕТОДИОД ====================
class LEDDevice extends Device {
  Color color;
  int brightness;
  bool isBlinking;

  LEDDevice({
    required String id,
    required String name,
    this.color = Colors.white,
    this.brightness = 100,
    this.isBlinking = false,
    bool isEnabled = false,
  }) : super(
          id: id,
          name: name,
          isEnabled: isEnabled,
          status: DeviceStatus.online,
        );

  void setBrightness(int value) {
    if (value >= 0 && value <= 100) {
      brightness = value;
    }
  }

  void toggleBlinking() {
    isBlinking = !isBlinking;
  }
}

// ==================== БАЗЗЕР ====================
class BuzzerDevice extends Device {
  int volume;
  BuzzerMode mode;

  BuzzerDevice({
    required String id,
    required String name,
    this.volume = 50,
    this.mode = BuzzerMode.continuous,
    bool isEnabled = false,
  }) : super(
          id: id,
          name: name,
          isEnabled: isEnabled,
          status: DeviceStatus.online,
        );

  void setVolume(int value) {
    if (value >= 0 && value <= 100) {
      volume = value;
    }
  }

  void setMode(BuzzerMode newMode) {
    mode = newMode;
  }
}

enum BuzzerMode {
  continuous,
  beep,
  alarm,
}

// ==================== СЕРВИС УПРАВЛЕНИЯ УСТРОЙСТВАМИ ====================
class DeviceService {
  // ТРЕВОГА
  static bool isAlarmActive = false;

  // Список всех устройств
  static List<SensorDevice> sensors = [
    SensorDevice(
      id: 's0',
      name: 'Sensor 0 - Entrance',
      distance: 15.0,
      alarmThreshold: 20.0,
    ),
    SensorDevice(
      id: 's1',
      name: 'Sensor 1 - Left Side',
      distance: 20.0,
      alarmThreshold: 20.0,
    ),
    SensorDevice(
      id: 's2',
      name: 'Sensor 2 - Right Side',
      distance: 10.0,
      alarmThreshold: 20.0,
    ),
  ];

  static ServoDevice servo = ServoDevice(
    id: 'servo1',
    name: 'Door Servo',
    openAngle: 0,
    closedAngle: 90,
  );

  static List<LEDDevice> leds = [
    LEDDevice(id: 'led1', name: 'LED 1 - Front', color: Colors.red),
    LEDDevice(id: 'led2', name: 'LED 2 - Left', color: Colors.red),
    LEDDevice(id: 'led3', name: 'LED 3 - Right', color: Colors.red),
    LEDDevice(id: 'led4', name: 'LED 4 - Back', color: Colors.red),
  ];

  static List<BuzzerDevice> buzzers = [
    BuzzerDevice(id: 'buzz1', name: 'Buzzer 1'),
    BuzzerDevice(id: 'buzz2', name: 'Buzzer 2'),
    BuzzerDevice(id: 'buzz3', name: 'Buzzer 3'),
  ];

  // Проверка, сработала ли тревога
  static bool checkAlarmTrigger() {
    for (var sensor in sensors) {
      if (sensor.isAlarmTriggered()) {
        return true;
      }
    }
    return false;
  }

  // АКТИВАЦИЯ ТРЕВОГИ
  static void activateAlarm() {
    isAlarmActive = true;
    
    // Включаем все LED
    for (var led in leds) {
      led.isEnabled = true;
      led.isBlinking = true;
    }
    
    // Включаем все баззеры
    for (var buzzer in buzzers) {
      buzzer.isEnabled = true;
    }
    
    // Закрываем дверь
    servo.closeDoor();
    
    print('🚨 ТРЕВОГА АКТИВИРОВАНА!');
  }

  // ДЕАКТИВАЦИЯ ТРЕВОГИ
  static void deactivateAlarm() {
    isAlarmActive = false;
    
    // Выключаем все LED
    for (var led in leds) {
      led.isEnabled = false;
      led.isBlinking = false;
    }
    
    // Выключаем все баззеры
    for (var buzzer in buzzers) {
      buzzer.isEnabled = false;
    }
    
    // Открываем дверь
    servo.openDoor();
    
    print('✅ Тревога деактивирована');
  }

  // Получить все устройства
  static List<Device> getAllDevices() {
    return [
      ...sensors,
      servo,
      ...leds,
      ...buzzers,
    ];
  }

  // Статистика
  static Map<String, int> getDeviceStats() {
    int totalDevices = getAllDevices().length;
    int onlineDevices = getAllDevices().where((d) => d.status == DeviceStatus.online).length;
    int enabledDevices = getAllDevices().where((d) => d.isEnabled).length;

    return {
      'total': totalDevices,
      'online': onlineDevices,
      'enabled': enabledDevices,
    };
  }

  // Emergency Stop - выключить все
  static void emergencyStop() {
    deactivateAlarm();
    
    for (var sensor in sensors) {
      sensor.isEnabled = false;
    }
    
    print('🛑 Emergency Stop активирован');
  }

  // Включить все
  static void enableAll() {
    for (var sensor in sensors) {
      sensor.isEnabled = true;
    }
    
    print('✅ Все устройства включены');
  }
}