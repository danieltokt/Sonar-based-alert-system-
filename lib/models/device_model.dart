// lib/models/device_model.dart

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

  // Метод для включения/выключения устройства
  void toggle() {
    isEnabled = !isEnabled;
  }
}

// ==================== СТАТУСЫ УСТРОЙСТВ ====================
enum DeviceStatus {
  online,    // Устройство подключено и работает
  offline,   // Устройство не подключено
  error,     // Ошибка устройства
  warning,   // Предупреждение
}

// ==================== СЕНСОР ====================
class SensorDevice extends Device {
  double distance; // Расстояние в сантиметрах
  final double maxDistance;
  final double minDistance;

  SensorDevice({
    required String id,
    required String name,
    required this.distance,
    this.maxDistance = 50.0,
    this.minDistance = 0.0,
    bool isEnabled = true,
  }) : super(
          id: id,
          name: name,
          isEnabled: isEnabled,
          status: DeviceStatus.online,
        );

  // Получить цвет индикатора в зависимости от расстояния
  Color getIndicatorColor() {
    if (!isEnabled) return Colors.grey;
    
    if (distance < 10) {
      return Colors.red; // Очень близко - опасность
    } else if (distance < 30) {
      return Colors.orange; // Близко - предупреждение
    } else {
      return Colors.green; // Далеко - нормально
    }
  }

  // Получить статус в текстовом виде
  String getStatusText() {
    if (!isEnabled) return 'Выключен';
    
    if (distance < 10) {
      return 'ОПАСНОСТЬ';
    } else if (distance < 30) {
      return 'ВНИМАНИЕ';
    } else {
      return 'НОРМА';
    }
  }
}

// ==================== КАМЕРА ====================
class CameraDevice extends Device {
  bool isRecording;
  int angle; // Угол поворота сервомотора (0-180)

  CameraDevice({
    required String id,
    required String name,
    this.isRecording = false,
    this.angle = 90,
  }) : super(
          id: id,
          name: name,
          isEnabled: true, // Камера ВСЕГДА включена
          status: DeviceStatus.online,
        );

  // Камера не может быть выключена
  @override
  void toggle() {
    // Камера всегда включена, но можем переключать запись
    isRecording = !isRecording;
  }

  // Повернуть камеру
  void rotateCamera(int newAngle) {
    if (newAngle >= 0 && newAngle <= 180) {
      angle = newAngle;
    }
  }
}

// ==================== СВЕТОДИОД ====================
class LEDDevice extends Device {
  Color color;
  int brightness; // 0-100
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

  // Изменить яркость
  void setBrightness(int value) {
    if (value >= 0 && value <= 100) {
      brightness = value;
    }
  }

  // Включить/выключить мигание
  void toggleBlinking() {
    isBlinking = !isBlinking;
  }
}

// ==================== БАЗЗЕР ====================
class BuzzerDevice extends Device {
  int volume; // 0-100
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

  // Изменить громкость
  void setVolume(int value) {
    if (value >= 0 && value <= 100) {
      volume = value;
    }
  }

  // Изменить режим
  void setMode(BuzzerMode newMode) {
    mode = newMode;
  }
}

enum BuzzerMode {
  continuous, // Постоянный звук
  beep,       // Короткие сигналы
  alarm,      // Сирена
}

// ==================== СЕРВИС УПРАВЛЕНИЯ УСТРОЙСТВАМИ ====================
class DeviceService {
  // Список всех устройств в системе
  static List<SensorDevice> sensors = [
    SensorDevice(id: 's0', name: 'Sensor 0 - Entrance', distance: 15.0),
    SensorDevice(id: 's1', name: 'Sensor 1 - Left Side', distance: 20.0),
    SensorDevice(id: 's2', name: 'Sensor 2 - Right Side', distance: 10.0),
  ];

  static CameraDevice camera = CameraDevice(
    id: 'cam1',
    name: 'Main Camera',
  );

  static List<LEDDevice> leds = [
    LEDDevice(id: 'led1', name: 'LED 1 - Front', color: Colors.red),
    LEDDevice(id: 'led2', name: 'LED 2 - Left', color: Colors.blue),
    LEDDevice(id: 'led3', name: 'LED 3 - Right', color: Colors.green),
    LEDDevice(id: 'led4', name: 'LED 4 - Back', color: Colors.yellow),
  ];

  static List<BuzzerDevice> buzzers = [
    BuzzerDevice(id: 'buzz1', name: 'Buzzer 1'),
    BuzzerDevice(id: 'buzz2', name: 'Buzzer 2'),
    BuzzerDevice(id: 'buzz3', name: 'Buzzer 3'),
  ];

  // Получить все устройства
  static List<Device> getAllDevices() {
    return [
      ...sensors,
      camera,
      ...leds,
      ...buzzers,
    ];
  }

  // Получить статистику устройств
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

  // Emergency Stop - выключить все кроме камеры
  static void emergencyStop() {
    for (var sensor in sensors) {
      sensor.isEnabled = false;
    }
    for (var led in leds) {
      led.isEnabled = false;
    }
    for (var buzzer in buzzers) {
      buzzer.isEnabled = false;
    }
    // Камера остается включенной
  }

  // Включить все устройства
  static void enableAll() {
    for (var sensor in sensors) {
      sensor.isEnabled = true;
    }
    for (var led in leds) {
      led.isEnabled = true;
    }
    for (var buzzer in buzzers) {
      buzzer.isEnabled = true;
    }
  }
}