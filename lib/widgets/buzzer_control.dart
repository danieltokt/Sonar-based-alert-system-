// lib/widgets/buzzer_control.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/connection_service.dart';

class BuzzerControl extends StatefulWidget {
  final List<BuzzerDevice> buzzers;
  final Function(String, bool) onToggle;

  BuzzerControl({
    required this.buzzers,
    required this.onToggle,
  });

  @override
  _BuzzerControlState createState() => _BuzzerControlState();
}

class _BuzzerControlState extends State<BuzzerControl> with TickerProviderStateMixin {
  late List<AnimationController> _waveControllers;

  @override
  void initState() {
    super.initState();
    _waveControllers = List.generate(
      widget.buzzers.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800),
      )..repeat(),
    );
  }

  @override
  void dispose() {
    for (var controller in _waveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get enabledCount => widget.buzzers.where((b) => b.isEnabled).length;

  void _toggleAll(bool value) async {
    for (var buzzer in widget.buzzers) {
      await ConnectionService.sendCommand(buzzer.id, 'toggle', value);
      setState(() {
        buzzer.isEnabled = value;
      });
      widget.onToggle(buzzer.id, value);
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
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.volume_up,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buzzers / Alarm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$enabledCount/${widget.buzzers.length} Active',
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
                  onPressed: () => _toggleAll(enabledCount < widget.buzzers.length),
                  child: Text(
                    enabledCount < widget.buzzers.length ? 'All ON' : 'All OFF',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Список баззеров
            ...widget.buzzers.asMap().entries.map((entry) {
              int index = entry.key;
              BuzzerDevice buzzer = entry.value;
              return _buildBuzzerCard(buzzer, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBuzzerCard(BuzzerDevice buzzer, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: buzzer.isEnabled ? Colors.purple : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Иконка с анимацией
              Stack(
                alignment: Alignment.center,
                children: [
                  if (buzzer.isEnabled)
                    AnimatedBuilder(
                      animation: _waveControllers[index],
                      builder: (context, child) {
                        return Container(
                          width: 40 + (20 * _waveControllers[index].value),
                          height: 40 + (20 * _waveControllers[index].value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.purple.withOpacity(
                              0.3 * (1 - _waveControllers[index].value),
                            ),
                          ),
                        );
                      },
                    ),
                  Icon(
                    buzzer.isEnabled ? Icons.notifications_active : Icons.notifications_outlined,
                    color: buzzer.isEnabled ? Colors.purple : Colors.grey[600],
                    size: 32,
                  ),
                ],
              ),
              SizedBox(width: 12),
              
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buzzer.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      buzzer.isEnabled ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: buzzer.isEnabled ? Colors.purple : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Переключатель
              Switch(
                value: buzzer.isEnabled,
                onChanged: (value) async {
                  bool success = await ConnectionService.sendCommand(
                    buzzer.id,
                    'toggle',
                    value,
                  );

                  if (success) {
                    setState(() {
                      buzzer.isEnabled = value;
                    });
                    widget.onToggle(buzzer.id, value);
                  }
                },
                activeColor: Colors.purple,
              ),
            ],
          ),
          
          // Громкость (показываем только если включен)
          if (buzzer.isEnabled) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.volume_down, color: Colors.grey[400], size: 20),
                Expanded(
                  child: Slider(
                    value: buzzer.volume.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${buzzer.volume}%',
                    onChanged: (value) {
                      setState(() {
                        buzzer.setVolume(value.toInt());
                      });
                    },
                    activeColor: Colors.purple,
                  ),
                ),
                Icon(Icons.volume_up, color: Colors.grey[400], size: 20),
              ],
            ),
            Text(
              'Volume: ${buzzer.volume}%',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }
}