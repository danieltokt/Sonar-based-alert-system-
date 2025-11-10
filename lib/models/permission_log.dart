// lib/models/permission_log.dart

class PermissionLog {
  final String username;
  final String permission;
  final bool granted;
  final DateTime timestamp;

  PermissionLog({
    required this.username,
    required this.permission,
    required this.granted,
    required this.timestamp,
  });

  String getActionText() {
    return granted ? 'предоставлен' : 'отозван';
  }

  String getDeviceName() {
    switch (permission) {
      case 'sensors':
        return '📡 Сенсоры';
      case 'camera':
        return '📹 Камера';
      case 'leds':
        return '💡 LED';
      case 'buzzers':
        return '🔊 Баззеры';
      default:
        return permission;
    }
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} сек назад';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else {
      return '${difference.inDays} дн назад';
    }
  }
}

// Сервис для хранения логов
class PermissionLogService {
  static List<PermissionLog> _logs = [];

  static List<PermissionLog> get logs => _logs;

  static void addLog(String username, String permission, bool granted) {
    _logs.insert(
      0,
      PermissionLog(
        username: username,
        permission: permission,
        granted: granted,
        timestamp: DateTime.now(),
      ),
    );

    // Храним только последние 50 записей
    if (_logs.length > 50) {
      _logs = _logs.sublist(0, 50);
    }
  }

  static void clear() {
    _logs.clear();
  }

  static List<PermissionLog> getLogsForUser(String username) {
    return _logs.where((log) => log.username == username).toList();
  }

  static int getTodayChangesCount() {
    final today = DateTime.now();
    return _logs.where((log) {
      return log.timestamp.year == today.year &&
          log.timestamp.month == today.month &&
          log.timestamp.day == today.day;
    }).length;
  }
}