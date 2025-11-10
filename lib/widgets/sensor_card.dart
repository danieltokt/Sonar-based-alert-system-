// lib/widgets/sensor_card.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class SensorCard extends StatefulWidget {
  final SensorDevice sensor;
  final Function(bool) onToggle;

  SensorCard({
    required this.sensor,
    required this.onToggle,
  });

  @override
  _SensorCardState createState() => _SensorCardState();
}

class _SensorCardState extends State<SensorCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[850],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с иконкой и переключателем
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.sensor.getIndicatorColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.radar,
                    color: widget.sensor.getIndicatorColor(),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sensor.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.sensor.getStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.sensor.getIndicatorColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.sensor.isEnabled,
                  onChanged: (value) async {
                    // Отправляем команду на Arduino
                    bool success = await ConnectionService.sendCommand(
                      widget.sensor.id,
                      'toggle',
                      value,
                    );

                    if (success) {
                      setState(() {
                        widget.sensor.isEnabled = value;
                      });
                      widget.onToggle(value);
                    }
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Индикатор расстояния
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.sensor.getIndicatorColor().withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.sensor.distance.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: widget.sensor.isEnabled
                              ? widget.sensor.getIndicatorColor()
                              : Colors.grey,
                        ),
                      ),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'см',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Прогресс бар
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: widget.sensor.isEnabled
                          ? (widget.sensor.distance / widget.sensor.maxDistance)
                          : 0,
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.sensor.getIndicatorColor(),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            // Статус подключения
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.sensor.status == DeviceStatus.online
                        ? Colors.green
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  widget.sensor.status == DeviceStatus.online
                      ? 'Online'
                      : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
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