// lib/models/user_model.dart

class UserModel {
  final String username;
  final String password;
  final UserRole role;
  Map<String, bool> permissions;

  UserModel({
    required this.username,
    required this.password,
    required this.role,
    required this.permissions,
  });

  // Проверка прав доступа к конкретному устройству
  bool hasPermission(String device) {
    return permissions[device] ?? false;
  }

  // Обновление прав доступа
  void updatePermission(String device, bool value) {
    permissions[device] = value;
  }
}

enum UserRole { userA, userB, userC, admin }

// Класс для управления пользователями и аутентификацией
class AuthService {
  // Hardcoded пользователи
  static final List<UserModel> _users = [
    UserModel(
      username: 'userA',
      password: 'pass123',
      role: UserRole.userA,
      permissions: {
        'sensors': true,
        'servo': true, // Было 'camera'
        'leds': true,
        'buzzers': true,
      },
    ),
    UserModel(
      username: 'userB',
      password: 'pass123',
      role: UserRole.userB,
      permissions: {
        'sensors': true,
        'servo': false, // Было 'camera'
        'leds': false,
        'buzzers': false,
      },
    ),
    UserModel(
      username: 'userC',
      password: 'pass123',
      role: UserRole.userC,
      permissions: {
        'sensors': false,
        'servo': true, // Было 'camera'
        'leds': false,
        'buzzers': true,
      },
    ),
    UserModel(
      username: 'admin',
      password: 'admin123',
      role: UserRole.admin,
      permissions: {
        'sensors': true,
        'servo': true, // Было 'camera'
        'leds': true,
        'buzzers': true,
      },
    ),
  ];

  // Текущий залогиненный пользователь
  static UserModel? _currentUser;

  // Получить текущего пользователя
  static UserModel? get currentUser => _currentUser;

  // Получить всех пользователей (кроме админа)
  static List<UserModel> getAllUsers() {
    return _users.where((user) => user.role != UserRole.admin).toList();
  }

  // Аутентификация
  static UserModel? login(String username, String password) {
    try {
      final user = _users.firstWhere(
        (user) => user.username == username && user.password == password,
      );
      _currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  // Выход
  static void logout() {
    _currentUser = null;
  }

  // Проверка, залогинен ли пользователь
  static bool isLoggedIn() {
    return _currentUser != null;
  }

  // Получить пользователя по username
  static UserModel? getUserByUsername(String username) {
    try {
      return _users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }
}
