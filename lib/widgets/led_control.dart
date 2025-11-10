// lib/widgets/led_control.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class LEDControl extends StatefulWidget {
  final List<LEDDevice> leds;
  final Function(String, bool) onToggle;

  LEDControl({
    required this.leds,
    required this.onToggle,
  });

  @override
  _LEDControlState createState() => _LEDControlState();
}

class _LEDControlState extends State<LEDControl> with TickerProviderStateMixin {
  late List<AnimationController> _blinkControllers;

  @override
  void initState() {
    super.initState();
    _blinkControllers = List.generate(
      widget.leds.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      )..repeat(reverse: true),
    );
  }

  @override
  void dispose() {
    for (var controller in _blinkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get enabledCount => widget.leds.where((led) => led.isEnabled).length;

  void _toggleAll(bool value) async {
    for (var led in widget.leds) {
      await ConnectionService.sendCommand(led.id, 'toggle', value);
      setState(() {
        led.isEnabled = value;
      });
      widget.onToggle(led.id, value);
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
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LED Lights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$enabledCount/${widget.leds.length} Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                // Кнопка включить/выключить все
                ElevatedButton(
                  onPressed: () => _toggleAll(enabledCount < widget.leds.length),
                  child: Text(
                    enabledCount < widget.leds.length ? 'All ON' : 'All OFF',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Сетка LED
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: widget.leds.length,
              itemBuilder: (context, index) {
                final led = widget.leds[index];
                return _buildLEDCard(led, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLEDCard(LEDDevice led, int index) {
    return GestureDetector(
      onTap: () async {
        bool newValue = !led.isEnabled;
        bool success = await ConnectionService.sendCommand(
          led.id,
          'toggle',
          newValue,
        );

        if (success) {
          setState(() {
            led.isEnabled = newValue;
          });
          widget.onToggle(led.id, newValue);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: led.isEnabled ? led.color : Colors.grey[700]!,
            width: 2,
          ),
          boxShadow: led.isEnabled
              ? [
                  BoxShadow(
                    color: led.color.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _blinkControllers[index],
              builder: (context, child) {
                return Icon(
                  led.isEnabled ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 40,
                  color: led.isEnabled
                      ? led.color.withOpacity(0.5 + 0.5 * _blinkControllers[index].value)
                      : Colors.grey[600],
                );
              },
            ),
            SizedBox(height: 8),
            Text(
              led.name.split(' - ')[1], // Показываем только позицию
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: led.isEnabled ? led.color : Colors.grey[500],
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: led.isEnabled
                    ? led.color.withOpacity(0.2)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                led.isEnabled ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: led.isEnabled ? led.color : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}