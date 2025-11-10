// lib/widgets/connection_status.dart

import 'package:flutter/material.dart';
import '../services/connection_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  @override
  _ConnectionStatusWidgetState createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  int _ping = 0;

  @override
  void initState() {
    super.initState();
    _updatePing();
  }

  Future<void> _updatePing() async {
    while (mounted) {
      if (ConnectionService.status == ConnectionStatus.connected) {
        int ping = await ConnectionService.ping();
        if (mounted) {
          setState(() {
            _ping = ping;
          });
        }
      }
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Color _getStatusColor() {
    switch (ConnectionService.status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (ConnectionService.status) {
      case ConnectionStatus.connected:
        return Icons.wifi;
      case ConnectionStatus.connecting:
        return Icons.wifi_tethering;
      case ConnectionStatus.disconnected:
        return Icons.wifi_off;
      case ConnectionStatus.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectionStatus>(
      stream: ConnectionService.statusStream,
      initialData: ConnectionService.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.disconnected;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getStatusColor().withOpacity(0.2),
                _getStatusColor().withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor().withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arduino Connection',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          ConnectionService.getStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Кнопки управления
                  if (status == ConnectionStatus.disconnected ||
                      status == ConnectionStatus.error)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ConnectionService.connect();
                        if (mounted) setState(() {});
                      },
                      icon: Icon(Icons.power, size: 16),
                      label: Text('Connect', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    )
                  else if (status == ConnectionStatus.connecting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  else
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh, size: 20),
                          onPressed: () async {
                            await ConnectionService.reconnect();
                            if (mounted) setState(() {});
                          },
                          color: Colors.blue,
                          tooltip: 'Reconnect',
                        ),
                        IconButton(
                          icon: Icon(Icons.power_off, size: 20),
                          onPressed: () async {
                            await ConnectionService.disconnect();
                            if (mounted) setState(() {});
                          },
                          color: Colors.red,
                          tooltip: 'Disconnect',
                        ),
                      ],
                    ),
                ],
              ),

              // Дополнительная информация при подключении
              if (status == ConnectionStatus.connected) ...[
                SizedBox(height: 12),
                Divider(color: Colors.grey[700], height: 1),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                      'Uptime',
                      ConnectionService.getConnectionDuration(),
                      Icons.timer,
                    ),
                    _buildInfoChip(
                      'Ping',
                      '${_ping}ms',
                      Icons.network_ping,
                    ),
                    _buildInfoChip(
                      'Signal',
                      _ping < 50 ? 'Excellent' : _ping < 100 ? 'Good' : 'Fair',
                      Icons.signal_cellular_alt,
                    ),
                  ],
                ),
              ],

              // Сообщение об ошибке
              if (status == ConnectionStatus.error &&
                  ConnectionService.lastError.isNotEmpty) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ConnectionService.lastError,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}