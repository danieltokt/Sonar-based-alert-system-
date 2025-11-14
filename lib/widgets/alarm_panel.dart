// lib/widgets/alarm_panel.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';

class AlarmPanel extends StatefulWidget {
  final bool isAlarmActive;
  final Function() onActivate;
  final Function() onDeactivate;

  AlarmPanel({
    required this.isAlarmActive,
    required this.onActivate,
    required this.onDeactivate,
  });

  @override
  _AlarmPanelState createState() => _AlarmPanelState();
}

class _AlarmPanelState extends State<AlarmPanel> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    
    if (widget.isAlarmActive) {
      _blinkController.repeat(reverse: true);
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(AlarmPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlarmActive && !oldWidget.isAlarmActive) {
      _blinkController.repeat(reverse: true);
      _pulseController.repeat();
    } else if (!widget.isAlarmActive && oldWidget.isAlarmActive) {
      _blinkController.stop();
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleAlarm() {
    if (widget.isAlarmActive) {
      // Деактивация
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 10),
              Text('Отключить тревогу?'),
            ],
          ),
          content: Text(
            'Вы уверены, что хотите отключить систему тревоги?\n\n'
            '✓ LED выключатся\n'
            '✓ Баззеры замолчат\n'
            '✓ Дверь откроется',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDeactivate();
              },
              child: Text('Отключить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      );
    } else {
      // Активация
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 10),
              Text('Включить тревогу?'),
            ],
          ),
          content: Text(
            'Вы уверены, что хотите ВКЛЮЧИТЬ систему тревоги?\n\n'
            '⚠️ LED начнут мигать\n'
            '⚠️ Баззеры включатся\n'
            '⚠️ Дверь закроется',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onActivate();
              },
              child: Text('Включить'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAlarmActive) {
      return _buildActiveAlarm();
    } else {
      return _buildInactiveAlarm();
    }
  }

  // ==================== АКТИВНАЯ ТРЕВОГА ====================
  Widget _buildActiveAlarm() {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red[900]!.withOpacity(0.5 + 0.5 * _blinkController.value),
                Colors.red[700]!.withOpacity(0.5 + 0.5 * _blinkController.value),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.withOpacity(0.5 + 0.5 * _blinkController.value),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5 * _blinkController.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Иконка тревоги
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + 0.2 * _pulseController.value,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              
              Text(
                '🚨 ТРЕВОГА АКТИВНА',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Система оповещения работает',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 20),

              // Статус системы
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildStatusRow('🚨 LED', 'Мигают', Colors.red),
                    Divider(color: Colors.white24, height: 16),
                    _buildStatusRow('🔊 Баззеры', 'Работают', Colors.orange),
                    Divider(color: Colors.white24, height: 16),
                    _buildStatusRow('🚪 Дверь', 'Закрыта', Colors.blue),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Кнопка деактивации
              ElevatedButton.icon(
                onPressed: _toggleAlarm,
                icon: Icon(Icons.cancel, size: 28),
                label: Text(
                  'ОТКЛЮЧИТЬ ТРЕВОГУ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Или нажмите физическую кнопку на Arduino',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== НЕАКТИВНАЯ ТРЕВОГА ====================
  Widget _buildInactiveAlarm() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Иконка
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          
          Text(
            'Система безопасности',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Тревога выключена',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),

          // Статус системы
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Column(
              children: [
                _buildStatusRow('🚨 LED', 'Выключены', Colors.grey),
                Divider(color: Colors.grey[700], height: 16),
                _buildStatusRow('🔊 Баззеры', 'Выключены', Colors.grey),
                Divider(color: Colors.grey[700], height: 16),
                _buildStatusRow('🚪 Дверь', 'Открыта', Colors.grey),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Кнопка активации
          ElevatedButton.icon(
            onPressed: _toggleAlarm,
            icon: Icon(Icons.notifications_active, size: 28),
            label: Text(
              'ВКЛЮЧИТЬ ТРЕВОГУ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 12),
          
          // Информация
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'При включении: LED замигают, баззеры включатся, дверь закроется',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[200],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}