// lib/widgets/servo_widget.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class ServoWidget extends StatefulWidget {
  final ServoDevice servo;
  final Function(int) onAngleChange;
  final Function(bool) onDoorToggle;

  ServoWidget({
    required this.servo,
    required this.onAngleChange,
    required this.onDoorToggle,
  });

  @override
  _ServoWidgetState createState() => _ServoWidgetState();
}

class _ServoWidgetState extends State<ServoWidget> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    if (widget.servo.isDoorClosed) {
      _rotationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggleDoor() async {
    if (widget.servo.isDoorClosed) {
      // Открыть дверь
      bool success = await ConnectionService.sendCommand(
        widget.servo.id,
        'open',
        widget.servo.openAngle,
      );
      
      if (success) {
        setState(() {
          widget.servo.openDoor();
        });
        _rotationController.reverse();
        widget.onDoorToggle(false);
      }
    } else {
      // Закрыть дверь
      bool success = await ConnectionService.sendCommand(
        widget.servo.id,
        'close',
        widget.servo.closedAngle,
      );
      
      if (success) {
        setState(() {
          widget.servo.closeDoor();
        });
        _rotationController.forward();
        widget.onDoorToggle(true);
      }
    }
  }

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
            // Заголовок
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.servo.isDoorClosed 
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.servo.isDoorClosed ? Icons.lock : Icons.lock_open,
                    color: widget.servo.isDoorClosed ? Colors.red : Colors.green,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.servo.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.servo.getDoorStatus(),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.servo.isDoorClosed ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Визуализация двери
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.servo.isDoorClosed 
                        ? Colors.red.withOpacity(0.5)
                        : Colors.green.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Рамка двери
                    Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!, width: 4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    
                    // Дверь (с анимацией поворота)
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(_rotationController.value * 1.57), // 90 градусов
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 110,
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.servo.isDoorClosed
                                    ? [Colors.red[900]!, Colors.red[700]!]
                                    : [Colors.blue[900]!, Colors.blue[700]!],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                widget.servo.isDoorClosed ? Icons.lock : Icons.lock_open,
                                size: 40,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Информация об угле
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem('Текущий угол', '${widget.servo.angle}°'),
                  Container(width: 1, height: 30, color: Colors.grey[700]),
                  _buildInfoItem('Статус', widget.servo.status == DeviceStatus.online ? 'Online' : 'Offline'),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Кнопки управления
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleDoor,
                    icon: Icon(
                      widget.servo.isDoorClosed ? Icons.lock_open : Icons.lock,
                    ),
                    label: Text(
                      widget.servo.isDoorClosed ? 'Открыть' : 'Закрыть',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.servo.isDoorClosed ? Colors.green : Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Слайдер для ручного управления углом
            Text(
              'Ручное управление:',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            Row(
              children: [
                Icon(Icons.rotate_left, color: Colors.grey[400], size: 20),
                Expanded(
                  child: Slider(
                    value: widget.servo.angle.toDouble(),
                    min: 0,
                    max: 180,
                    divisions: 18,
                    label: '${widget.servo.angle}°',
                    onChanged: (value) async {
                      int newAngle = value.toInt();
                      bool success = await ConnectionService.sendCommand(
                        widget.servo.id,
                        'setAngle',
                        newAngle,
                      );
                      
                      if (success) {
                        setState(() {
                          widget.servo.setAngle(newAngle);
                        });
                        widget.onAngleChange(newAngle);
                      }
                    },
                    activeColor: Colors.blue,
                  ),
                ),
                Icon(Icons.rotate_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}