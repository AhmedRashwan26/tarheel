import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../core/socket/socket_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  
  AuthStatus _status = AuthStatus.initial;
  String? _token;
  String _userRole = 'CLIENT'; // 'CLIENT' or 'DRIVER'
  Map<String, dynamic>? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get token => _token;
  String get userRole => _userRole;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get currentUser => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isDriver => _userRole == 'DRIVER';

  void setRole(String role) {
    _userRole = role;
    StorageService.saveRole(role);
    notifyListeners();
  }

  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _token = await StorageService.getToken();
    final savedRole = await StorageService.getRole();
    if (savedRole != null) _userRole = savedRole;

    if (_token != null && _token!.isNotEmpty) {
      try {
        final response = await _api.get(ApiEndpoints.userProfile);
        _user = response.data['data'];
        _userRole = _user?['role'] ?? _userRole;
        _status = AuthStatus.authenticated;
        
        if (_user?['id'] != null) {
          SocketService().initSocket(_user!['id']);
        }
      } catch (e) {
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> sendOtp(String identifier, {String channel = 'WHATSAPP'}) async {
    _errorMessage = null;
    try {
      final response = await _api.post(
        ApiEndpoints.sendOtp,
        data: {'identifier': identifier, 'channel': channel},
      );
      return response.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل إرسال رمز التحقق';
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String identifier, String code) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.verifyOtp,
        data: {'identifier': identifier, 'code': code},
      );

      final data = response.data['data'];
      _token = data['accessToken'];
      _user = data['user'];
      _userRole = _user?['role'] ?? _userRole;

      if (_token != null) {
        await StorageService.saveToken(_token!);
        await StorageService.saveRole(_userRole);
        if (_user != null) await StorageService.saveUserProfile(_user!);
        if (_user?['id'] != null) SocketService().initSocket(_user!['id']);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'رمز التحقق غير صحيح';
      } else {
        _errorMessage = 'رمز التحقق غير صحيح';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerClient({required String fullName, String? phoneNumber, String? email}) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.registerClient,
        data: {
          'fullName': fullName,
          if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final data = response.data['data'];
      _token = data['accessToken'];
      _user = data['user'];
      _userRole = 'CLIENT';

      if (_token != null) {
        await StorageService.saveToken(_token!);
        await StorageService.saveRole(_userRole);
        if (_user != null) await StorageService.saveUserProfile(_user!);
        if (_user?['id'] != null) SocketService().initSocket(_user!['id']);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل إنشاء الحساب';
      } else {
        _errorMessage = 'فشل إنشاء الحساب';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerDriver(Map<String, dynamic> driverData) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.registerDriver,
        data: driverData,
      );

      final data = response.data['data'];
      _token = data['accessToken'];
      _user = data['driverProfile']?['user'] ?? {'role': 'DRIVER'};
      _userRole = 'DRIVER';

      if (_token != null) {
        await StorageService.saveToken(_token!);
        await StorageService.saveRole(_userRole);
        if (_user != null) await StorageService.saveUserProfile(_user!);
        if (_user?['id'] != null) SocketService().initSocket(_user!['id']);
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      if (e is DioException) {
        _errorMessage = e.error?.toString() ?? 'فشل تسجيل بيانات السائق';
      } else {
        _errorMessage = 'فشل تسجيل بيانات السائق';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await StorageService.clear();
    SocketService().disconnect();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
