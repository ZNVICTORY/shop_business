import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地演示账号：接后端时改为 token + API。
class AuthStore extends ChangeNotifier {
  static const _kEmail = 'auth_email';
  static const _kName = 'auth_name';
  static const _kPassword = 'auth_password';

  String? _email;
  String? _displayName;
  String? _password;

  String? get email => _email;
  String? get displayName => _displayName;
  bool get isLoggedIn =>
      _email != null && _email!.isNotEmpty && _password != null;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _email = p.getString(_kEmail);
    _displayName = p.getString(_kName);
    _password = p.getString(_kPassword);
    notifyListeners();
  }

  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || password.isEmpty || displayName.trim().isEmpty) {
      return '请填写完整信息';
    }
    final p = await SharedPreferences.getInstance();
    final existing = p.getString(_kEmail);
    if (existing != null && existing == trimmed) {
      return '该邮箱已注册，请直接登录';
    }
    await p.setString(_kEmail, trimmed);
    await p.setString(_kName, displayName.trim());
    await p.setString(_kPassword, password);
    _email = trimmed;
    _displayName = displayName.trim();
    _password = password;
    notifyListeners();
    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final p = await SharedPreferences.getInstance();
    final savedEmail = p.getString(_kEmail);
    final savedPass = p.getString(_kPassword);
    final name = p.getString(_kName);
    final trimmed = email.trim();
    if (savedEmail == null || savedPass == null) {
      return '请先注册账号';
    }
    if (trimmed != savedEmail || password != savedPass) {
      return '邮箱或密码错误';
    }
    _email = savedEmail;
    _displayName = name ?? '用户';
    _password = savedPass;
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kEmail);
    await p.remove(_kName);
    await p.remove(_kPassword);
    _email = null;
    _displayName = null;
    _password = null;
    notifyListeners();
  }
}
