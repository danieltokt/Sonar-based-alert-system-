// ==================== lib/widgets/sensor_card.dart ====================
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class SensorCard extends StatelessWidget {
  final SensorDevice sensor;
  final Function(bool) onToggle;

  SensorCard({required this.sensor, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sensors,
                  color: sensor.getIndicatorColor(),
                  size: 30,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensor.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        sensor.getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: sensor.getIndicatorColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: sensor.isEnabled,
                  onChanged: (value) {
                    sensor.isEnabled = value;
                    ConnectionService.sendCommand(sensor.id, '', value);
                    onToggle(value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: sensor.distance / sensor.maxDistance,
                    backgroundColor: Colors.grey[700],
                    valueColor: AlwaysStoppedAnimation(sensor.getIndicatorColor()),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '${sensor.distance.toInt()} см',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: sensor.getIndicatorColor(),
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

// ==================== lib/widgets/servo_widget.dart ====================
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class ServoWidget extends StatelessWidget {
  final ServoDevice servo;
  final Function(int) onAngleChange;
  final Function(bool) onDoorToggle;

  ServoWidget({
    required this.servo,
    required this.onAngleChange,
    required this.onDoorToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  servo.isDoorClosed ? Icons.door_front_door : Icons.door_front_door_outlined,
                  color: servo.isDoorClosed ? Colors.red : Colors.green,
                  size: 40,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servo.name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        servo.getDoorStatus(),
                        style: TextStyle(
                          fontSize: 14,
                          color: servo.isDoorClosed ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      servo.openDoor();
                      ConnectionService.sendCommand(servo.id, 'open', 0);
                      onDoorToggle(false);
                    },
                    icon: Icon(Icons.lock_open),
                    label: Text('Открыть'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      servo.closeDoor();
                      ConnectionService.sendCommand(servo.id, 'close', 90);
                      onDoorToggle(true);
                    },
                    icon: Icon(Icons.lock),
                    label: Text('Закрыть'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Угол: ${servo.angle}°', style: TextStyle(fontSize: 14)),
            Slider(
              value: servo.angle.toDouble(),
              min: 0,
              max: 180,
              divisions: 18,
              label: '${servo.angle}°',
              onChanged: (value) {
                servo.setAngle(value.toInt());
                onAngleChange(value.toInt());
              },
              onChangeEnd: (value) {
                ConnectionService.sendCommand(servo.id, 'setAngle', value.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== lib/widgets/led_control.dart ====================
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class LEDControl extends StatelessWidget {
  final List<LEDDevice> leds;
  final Function(String, bool) onToggle;

  LEDControl({required this.leds, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: leds.map((led) => _buildLEDTile(led)).toList(),
        ),
      ),
    );
  }

  Widget _buildLEDTile(LEDDevice led) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: led.isEnabled ? led.color : Colors.grey[700],
              shape: BoxShape.circle,
              boxShadow: led.isEnabled
                  ? [BoxShadow(color: led.color, blurRadius: 10)]
                  : [],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              led.name,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: led.isEnabled,
            onChanged: (value) {
              led.isEnabled = value;
              ConnectionService.sendCommand(led.id, '', value);
              onToggle(led.id, value);
            },
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}

// ==================== lib/widgets/buzzer_control.dart ====================
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class BuzzerControl extends StatelessWidget {
  final List<BuzzerDevice> buzzers;
  final Function(String, bool) onToggle;

  BuzzerControl({required this.buzzers, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: buzzers.map((buzzer) => _buildBuzzerTile(buzzer)).toList(),
        ),
      ),
    );
  }

  Widget _buildBuzzerTile(BuzzerDevice buzzer) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            buzzer.isEnabled ? Icons.volume_up : Icons.volume_off,
            color: buzzer.isEnabled ? Colors.purple : Colors.grey,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              buzzer.name,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: buzzer.isEnabled,
            onChanged: (value) {
              buzzer.isEnabled = value;
              ConnectionService.sendCommand(buzzer.id, '', value);
              onToggle(buzzer.id, value);
            },
            activeColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}

// ==================== lib/widgets/connection_status.dart ====================
import 'package:flutter/material.dart';
import '../services/connection_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  @override
  _ConnectionStatusWidgetState createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  @override
  void initState() {
    super.initState();
    ConnectionService.statusStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ConnectionService.getStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (ConnectionService.status == ConnectionStatus.connected)
                  Text(
                    'Подключено: ${ConnectionService.getConnectionDuration()}',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                if (ConnectionService.status == ConnectionStatus.error)
                  Text(
                    ConnectionService.lastError,
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (ConnectionService.status != ConnectionStatus.connecting)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () async {
                await ConnectionService.reconnect();
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (ConnectionService.status) {
      case ConnectionStatus.connected:
        return Colors.green[700]!;
      case ConnectionStatus.connecting:
        return Colors.orange[700]!;
      case ConnectionStatus.disconnected:
        return Colors.grey[700]!;
      case ConnectionStatus.error:
        return Colors.red[700]!;
    }
  }

  IconData _getStatusIcon() {
    switch (ConnectionService.status) {
      case ConnectionStatus.connected:
        return Icons.bluetooth_connected;
      case ConnectionStatus.connecting:
        return Icons.bluetooth_searching;
      case ConnectionStatus.disconnected:
        return Icons.bluetooth_disabled;
      case ConnectionStatus.error:
        return Icons.error;
    }
  }
}

// ==================== lib/widgets/alarm_panel.dart ====================
import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class AlarmPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: DeviceService.isAlarmActive ? Colors.red[900] : Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              DeviceService.isAlarmActive ? Icons.alarm_on : Icons.alarm_off,
              color: DeviceService.isAlarmActive ? Colors.white : Colors.grey,
              size: 50,
            ),
            SizedBox(height: 12),
            Text(
              DeviceService.isAlarmActive ? '🚨 ТРЕВОГА АКТИВНА' : 'Тревога выключена',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DeviceService.isAlarmActive ? Colors.white : Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (DeviceService.isAlarmActive) {
                  DeviceService.deactivateAlarm();
                  ConnectionService.sendCommand('alarm', '', false);
                } else {
                  DeviceService.activateAlarm();
                  ConnectionService.sendCommand('alarm', '', true);
                }
              },
              icon: Icon(
                DeviceService.isAlarmActive ? Icons.stop : Icons.play_arrow,
              ),
              label: Text(
                DeviceService.isAlarmActive ? 'ВЫКЛЮЧИТЬ' : 'АКТИВИРОВАТЬ',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    DeviceService.isAlarmActive ? Colors.green : Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}