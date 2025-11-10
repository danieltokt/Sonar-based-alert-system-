// lib/widgets/camera_widget.dart

import 'package:flutter/material.dart';
import '../models/device_model.dart';

class CameraWidget extends StatefulWidget {
  final CameraDevice camera;
  final Function(bool) onRecordingToggle;

  CameraWidget({
    required this.camera,
    required this.onRecordingToggle,
  });

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[850],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.videocam,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.camera.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _blinkController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(_blinkController.value),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Камера ВСЕГДА включена, показываем индикатор
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Text(
                    'ALWAYS ON',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Видео превью (placeholder)
          Container(
            height: 200,
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
            ),
            child: Stack(
              children: [
                // Сетка (имитация видео)
                Center(
                  child: Icon(
                    Icons.video_camera_front,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                
                // Перекрестие
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Горизонтальная линия
                        Center(
                          child: Container(
                            height: 1,
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                        // Вертикальная линия
                        Center(
                          child: Container(
                            width: 1,
                            color: Colors.green.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Информация на видео
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),

                // Индикатор записи
                if (widget.camera.isRecording)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7 * _blinkController.value),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'REC',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Управление
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Кнопка записи
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            widget.camera.isRecording = !widget.camera.isRecording;
                          });
                          widget.onRecordingToggle(widget.camera.isRecording);
                        },
                        icon: Icon(
                          widget.camera.isRecording ? Icons.stop : Icons.fiber_manual_record,
                        ),
                        label: Text(
                          widget.camera.isRecording ? 'Stop Recording' : 'Start Recording',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.camera.isRecording ? Colors.red : Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Управление сервомотором
                Row(
                  children: [
                    Icon(Icons.rotate_left, color: Colors.grey[400], size: 20),
                    Expanded(
                      child: Slider(
                        value: widget.camera.angle.toDouble(),
                        min: 0,
                        max: 180,
                        divisions: 18,
                        label: '${widget.camera.angle}°',
                        onChanged: (value) {
                          setState(() {
                            widget.camera.rotateCamera(value.toInt());
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ),
                    Icon(Icons.rotate_right, color: Colors.grey[400], size: 20),
                  ],
                ),
                Text(
                  'Camera Angle: ${widget.camera.angle}°',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}