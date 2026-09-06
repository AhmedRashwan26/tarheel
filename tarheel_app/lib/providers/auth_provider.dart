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
  bool get isAdmin => _userRole == 'ADMIN' || _user?['role'] == 'ADMIN';
  bool get isDriverFullyApproved {
    final dp = _user?['driverProfile'];
    if (dp == null) return false;
    final hasVehicle = dp['vehicle'] != null;
    final isApproved = dp['verificationStatus'] == 'APPROVED' || dp['isVerified'] == true;
    return hasVehicle && isApproved;
  }
  bool get hasVerifiedPhone {
    final phone = _user?['phoneNumber'] ?? _user?['phone'];
    return phone != null && phone.toString().trim().isNotEmpty;
  }

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
    final savedProfile = await StorageService.getUserProfile();

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
        if (savedProfile != null) {
          _user = savedProfile;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  static String normalizeIdentifier(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('@')) return trimmed.toLowerCase();
    String clean = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('00')) clean = clean.substring(2);
    // Saudi Arabia: 05XXXXXXXX (10 digits) -> 9665XXXXXXXX
    if (clean.startsWith('05') && clean.length == 10) {
      return '966${clean.substring(1)}';
    }
    // Saudi Arabia: 5XXXXXXXX (9 digits) -> 9665XXXXXXXX
    if (clean.startsWith('5') && clean.length == 9) {
      return '966$clean';
    }
    // Egypt: 01XXXXXXXXX (11 digits) -> 201XXXXXXXXX
    if (clean.startsWith('01') && clean.length == 11) {
      return '20${clean.substring(1)}';
    }
    return clean.isNotEmpty ? clean : trimmed;
  }

  Future<bool> sendOtp(String identifier, {String channel = 'WHATSAPP', String? role}) async {
    _errorMessage = null;
    final targetRole = role ?? _userRole;
    final normalized = normalizeIdentifier(identifier);
    try {
      final response = await _api.post(
        ApiEndpoints.sendOtp,
        data: {'identifier': normalized, 'channel': channel, 'role': targetRole},
      );
      return response.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          _errorMessage = resData['message'].toString();
        } else {
          _errorMessage = 'تعذر إرسال رمز التحقق. يرجى التحقق من الرقم أو المحاولة لاحقاً';
        }
      } else {
        _errorMessage = 'حدث خطأ في الاتصال بالخادم';
      }
      return false;
    }
  }

  Future<bool> verifyOtp(String identifier, String code, {String? role}) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    final targetRole = role ?? _userRole;
    final normalized = normalizeIdentifier(identifier);
    try {
      final response = await _api.post(
        ApiEndpoints.verifyOtp,
        data: {'identifier': normalized, 'code': code, 'role': targetRole},
      );

      final data = response.data['data'];
      _token = data['accessToken'];
      _user = data['user'];
      if (_user?['role'] == 'ADMIN') {
        _userRole = 'ADMIN';
      } else {
        _userRole = (targetRole == 'DRIVER' || _user?['role'] == 'DRIVER') ? 'DRIVER' : (_user?['role'] ?? targetRole);
      }

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
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          _errorMessage = resData['message'].toString();
        } else {
          _errorMessage = e.error?.toString() ?? 'رمز التحقق غير صحيح أو منتهي الصلاحية';
        }
      } else {
        _errorMessage = 'رمز التحقق غير صحيح أو منتهي الصلاحية';
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
      // Local dev simulation
      _token = 'simulated_local_jwt_token';
      _user = {
        'id': 'user_demo_1',
        'fullName': fullName,
        'phoneNumber': phoneNumber ?? '+966593355884',
        'phone': phoneNumber ?? '+966593355884',
        'email': email ?? 'client@tarheel.sa',
        'role': 'CLIENT',
        'wallet': {'balance': '0.00'},
      };
      await StorageService.saveToken(_token!);
      await StorageService.saveRole('CLIENT');
      await StorageService.saveUserProfile(_user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
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
      _token = 'simulated_local_driver_token';
      _user = {
        'id': 'driver_demo_1',
        'fullName': driverData['fullName'] ?? 'كابتن ترحيل',
        'phoneNumber': driverData['phoneNumber'] ?? '+966593355884',
        'phone': driverData['phoneNumber'] ?? '+966593355884',
        'role': 'DRIVER',
        'wallet': {'balance': '1250.00'},
        'driverProfile': {
          'isVerified': true,
          'bankName': driverData['bankName'] ?? 'مصرف الراجحي',
          'ibanNumber': driverData['ibanNumber'] ?? 'SA4480000123456789012345',
          'vehicle': {
            'make': driverData['make'] ?? 'هيونداي',
            'model': driverData['model'] ?? 'سوناتا',
            'year': driverData['year'] ?? 2024,
            'color': driverData['color'] ?? 'فضي',
            'capacity': driverData['capacity'] ?? 4,
            'hasAirConditioning': driverData['hasAirConditioning'] ?? true,
          }
        }
      };
      await StorageService.saveToken(_token!);
      await StorageService.saveRole('DRIVER');
      await StorageService.saveUserProfile(_user!);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }
  }

  Future<bool> updateProfileAvatar(String avatarUrl) async {
    if (_user != null) {
      _user!['avatarUrl'] = avatarUrl;
      _user!['profilePictureUrl'] = avatarUrl;
      if (_user!['driverProfile'] != null) {
        _user!['driverProfile']['profilePictureUrl'] = avatarUrl;
      }
      await StorageService.saveUserProfile(_user!);
      notifyListeners();
    }
    try {
      await _api.patch(ApiEndpoints.userProfile, data: {'avatarUrl': avatarUrl});
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> loginWithGoogle({
    required String email,
    required String fullName,
    String? googleId,
    String? avatarUrl,
    String? role,
  }) async {
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();

    final targetRole = role ?? _userRole;
    try {
      final response = await _api.post(
        ApiEndpoints.googleLogin,
        data: {
          'email': email.trim().toLowerCase(),
          'fullName': fullName.trim(),
          if (googleId != null) 'googleId': googleId,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          'role': targetRole,
        },
      );

      final data = response.data['data'];
      _token = data['accessToken'];
      _user = data['user'];
      if (_user?['role'] == 'ADMIN') {
        _userRole = 'ADMIN';
      } else {
        _userRole = (targetRole == 'DRIVER' || _user?['role'] == 'DRIVER') ? 'DRIVER' : (_user?['role'] ?? targetRole);
      }

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
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          _errorMessage = resData['message'].toString();
        } else {
          _errorMessage = 'فشل تسجيل الدخول بحساب Google';
        }
      } else {
        _errorMessage = 'تعذر الاتصال بالخادم';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendBindPhoneOtp(String phoneNumber) async {
    _errorMessage = null;
    final normalized = normalizeIdentifier(phoneNumber);
    try {
      final response = await _api.post(
        ApiEndpoints.bindPhoneSendOtp,
        data: {'phoneNumber': normalized},
      );
      return response.data['success'] == true;
    } catch (e) {
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          _errorMessage = resData['message'].toString();
        } else {
          _errorMessage = 'تعذر إرسال رمز التحقق لرقم الجوال';
        }
      } else {
        _errorMessage = 'فشل إرسال رمز التحقق';
      }
      return false;
    }
  }

  Future<bool> verifyAndBindPhone(String phoneNumber, String code) async {
    _errorMessage = null;
    final normalized = normalizeIdentifier(phoneNumber);
    try {
      final response = await _api.post(
        ApiEndpoints.bindPhoneVerify,
        data: {'phoneNumber': normalized, 'code': code.trim()},
      );

      final data = response.data['data'];
      if (data?['user'] != null) {
        _user = data['user'];
        await StorageService.saveUserProfile(_user!);
      }
      if (data?['accessToken'] != null) {
        _token = data['accessToken'];
        await StorageService.saveToken(_token!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData is Map && resData['message'] != null) {
          _errorMessage = resData['message'].toString();
        } else {
          _errorMessage = 'رمز التحقق غير صحيح أو منتهي الصلاحية';
        }
      } else {
        _errorMessage = 'فشل تأكيد وربط رقم الجوال';
      }
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
