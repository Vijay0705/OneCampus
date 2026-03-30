import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _errorMessage;
  bool _authenticated = false;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authenticated;

  Future<void> tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null) return;
    try {
      final res = await ApiService.get(AppConstants.profileUrl);
      final userData = res['data']?['user'] ?? res['user'] ?? res;
      _user = UserModel.fromJson(userData as Map<String, dynamic>);
      _authenticated = true;
    } catch (_) {
      await ApiService.clearToken();
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.post(
        AppConstants.loginUrl,
        {'email': email, 'password': password},
        auth: false,
      );
      final data = res['data'] as Map<String, dynamic>? ?? res;
      await ApiService.saveToken(data['token'] as String);
      _user = UserModel.fromJson(
        (data['user'] ?? data) as Map<String, dynamic>,
      );
      _authenticated = true;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Check your connection.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String rollNumber,
    required String department,
    required int year,
  }) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await ApiService.post(
        AppConstants.registerUrl,
        {
          'name': name,
          'email': email,
          'password': password,
          'rollNumber': rollNumber,
          'department': department,
          'year': year,
          'role': 'student',
        },
        auth: false,
      );
      final data = res['data'] as Map<String, dynamic>? ?? res;
      await ApiService.saveToken(data['token'] as String);
      _user = UserModel.fromJson(
        (data['user'] ?? data) as Map<String, dynamic>,
      );
      _authenticated = true;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage =
          'Registration failed. Check your connection.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    _authenticated = false;
    notifyListeners();
  }
}