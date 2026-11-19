import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../models/user_profile.dart';
import '../services/auth_api_service.dart';

enum SessionStatus {
  booting,
  unauthenticated,
  awaitingTwoFactor,
  authenticated,
}

class SessionController extends ChangeNotifier {
  SessionController({
    required AuthApiService apiService,
    FlutterSecureStorage? secureStorage,
  }) : _apiService = apiService,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _sessionStorageKey = 'ey_mobile_auth_session';

  final AuthApiService _apiService;
  final FlutterSecureStorage _secureStorage;

  SessionStatus _status = SessionStatus.booting;
  bool _isBusy = false;
  String? _errorKey;
  String? _pendingUserId;
  AuthSession? _session;

  SessionStatus get status => _status;
  bool get isBusy => _isBusy;
  /// AppTexts key of the last error, to translate in the UI.
  String? get errorKey => _errorKey;
  String? get pendingUserId => _pendingUserId;
  AuthSession? get session => _session;
  UserProfile? get user => _session?.utilisateur;

  Future<void> bootstrap() async {
    _status = SessionStatus.booting;
    notifyListeners();

    try {
      final rawSession = await _readStoredSession();
      if (rawSession == null || rawSession.isEmpty) {
        _status = SessionStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(rawSession);
      if (decoded is! Map<String, dynamic>) {
        _status = SessionStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _session = AuthSession.fromJson(decoded);
      _status = SessionStatus.authenticated;
    } catch (_) {
      _session = null;
      _status = SessionStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (_isBusy) return false;
    _setBusy(true);
    _errorKey = null;
    notifyListeners();

    try {
      final result = await _apiService.login(
        email: email.trim(),
        motDePasse: password,
      );

      if (result.requiresTwoFactor) {
        _session = null;
        _pendingUserId = result.pendingUserId;
        _status = SessionStatus.awaitingTwoFactor;
        return true;
      }

      _session = result.session;
      _pendingUserId = null;
      _status = SessionStatus.authenticated;
      await _persistSession();
      return true;
    } on ApiException catch (error) {
      debugPrint('Login failed: ${error.message}');
      _errorKey = 'login.failed';
      _status = SessionStatus.unauthenticated;
      return false;
    } catch (error) {
      debugPrint('Login failed: $error');
      _errorKey = 'login.failed';
      _status = SessionStatus.unauthenticated;
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> verifyTwoFactorCode(String code) async {
    if (_isBusy) return false;
    if (_pendingUserId == null || _pendingUserId!.isEmpty) {
      _errorKey = 'otp.sessionMissing';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    _errorKey = null;
    notifyListeners();

    try {
      final session = await _apiService.verifyTwoFactor(
        utilisateurId: _pendingUserId!,
        code: code.trim(),
      );
      _session = session;
      _pendingUserId = null;
      _status = SessionStatus.authenticated;
      await _persistSession();
      return true;
    } on ApiException catch (error) {
      debugPrint('2FA failed: ${error.message}');
      _errorKey = 'otp.failed';
      return false;
    } catch (error) {
      debugPrint('2FA failed: $error');
      _errorKey = 'otp.failed';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    final currentSession = _session;

    _setBusy(true);
    notifyListeners();

    try {
      if (currentSession != null) {
        await _apiService.logout(refreshToken: currentSession.refreshToken);
      }
    } catch (_) {
    } finally {
      await _deleteStoredSession();
      _session = null;
      _pendingUserId = null;
      _errorKey = null;
      _status = SessionStatus.unauthenticated;
      _setBusy(false);
      notifyListeners();
    }
  }

  void cancelTwoFactor() {
    _pendingUserId = null;
    _errorKey = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorKey == null) {
      return;
    }
    _errorKey = null;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    if (_session == null) {
      await _deleteStoredSession();
      return;
    }

    await _writeStoredSession(jsonEncode(_session!.toJson()));
  }

  Future<String?> _readStoredSession() async {
    if (kIsWeb && kDebugMode) {
      return (await SharedPreferences.getInstance()).getString(
        _sessionStorageKey,
      );
    }
    return _secureStorage.read(key: _sessionStorageKey);
  }

  Future<void> _writeStoredSession(String value) async {
    if (kIsWeb && kDebugMode) {
      await (await SharedPreferences.getInstance()).setString(
        _sessionStorageKey,
        value,
      );
      return;
    }
    await _secureStorage.write(key: _sessionStorageKey, value: value);
  }

  Future<void> _deleteStoredSession() async {
    if (kIsWeb && kDebugMode) {
      await (await SharedPreferences.getInstance()).remove(_sessionStorageKey);
      return;
    }
    await _secureStorage.delete(key: _sessionStorageKey);
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
