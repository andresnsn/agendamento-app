import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiService);

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get error => _error;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _apiService.setAuthToken(token);
      final userData = prefs.getString('user_data');
      if (userData != null) {
        try {
          _user = UserModel.fromJson(
            Map<String, dynamic>.from(
              Uri.splitQueryString(userData).map(
                    (key, value) => MapEntry(key, value),
                  ),
            ),
          );
        } catch (_) {
          await prefs.remove('auth_token');
          await prefs.remove('user_data');
        }
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.login(email, password);
      final token = data['token'] as String;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _apiService.setAuthToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro de conexão. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password,
      {String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data =
          await _apiService.register(name, email, password, phone: phone);
      final token = data['token'] as String;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _apiService.setAuthToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Erro de conexão. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _apiService.setAuthToken('');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }
}
