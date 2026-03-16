import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uae_ecom_project/features/auth/model/auth_response_model.dart';
import 'package:uae_ecom_project/features/auth/model/login_model.dart';
import 'package:uae_ecom_project/features/auth/model/otp_model.dart';
import 'package:uae_ecom_project/features/auth/model/register_model.dart';
import 'package:uae_ecom_project/features/auth/model/user_model.dart';
import 'package:uae_ecom_project/features/auth/service/auth_service.dart';
import 'package:uae_ecom_project/service/token_storage.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpSent = false;

  // ─── Getters ────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isOtpSent => _isOtpSent;

  // ─── State Helpers ──────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Handle Auth Response ───────────────────────────────────
  Future<void> _handleAuthResponse(AuthResponse response) async {
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    
    // If user object is provided in response, use it. 
    // Otherwise, fetch it from /users/me/
    if (response.user != null) {
      if (_currentUser != null && response.rawUserJson != null) {
        // Always merge to preserve flags like isEmailVerified/isPhoneVerified
        _currentUser = UserModel.merge(_currentUser!, response.rawUserJson!);
      } else if (_currentUser != null) {
        // Merge even when rawUserJson is null, using the parsed user's toJson()
        _currentUser = UserModel.merge(_currentUser!, response.user!.toJson());
      } else {
        _currentUser = response.user;
      }
    } else {
      try {
        final freshUser = await _authService.getCurrentUser();
        if (_currentUser != null) {
          // Merge to preserve locally-set verification flags
          _currentUser = UserModel.merge(_currentUser!, freshUser.toJson());
        } else {
          _currentUser = freshUser;
        }
      } catch (e) {
        debugPrint('Error fetching user profile after auth: $e');
      }
    }

    if (_currentUser != null) {
      await _tokenStorage.saveUserData(_currentUser!.toJson());
    }
    notifyListeners();
  }

  // ─── Extract Error Message ──────────────────────────────────
  String _extractError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      // Try common error keys
      if (data.containsKey('detail')) return data['detail'].toString();
      if (data.containsKey('message')) return data['message'].toString();
      if (data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'];
        if (errors is List && errors.isNotEmpty) return errors.first.toString();
      }
      // Return first field error
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String) return value;
      }
    }
    return e.message ?? 'An unexpected error occurred';
  }

  // ─── Login (Email/Password) ─────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _authService.login(request);
      await _handleAuthResponse(response);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorMsg = _extractError(e);
      _setError(statusCode != null
          ? '[$statusCode] $errorMsg'
          : errorMsg);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ─── Register ───────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final request = RegisterRequest(
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
      );
      final response = await _authService.register(request);
      
      // If the registration response doesn't have tokens, we need to log in explicitly
      if (response.accessToken.isEmpty) {
        debugPrint('Registration successful but no tokens returned. Performing auto-login...');
        final loginResponse = await _authService.login(LoginRequest(email: email, password: password));
        await _handleAuthResponse(loginResponse);
      } else {
        await _handleAuthResponse(response);
      }
      
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ─── Request OTP ────────────────────────────────────────────
  Future<bool> requestOtp({required String identifier}) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.requestOtp(OtpRequestModel(identifier: identifier));
      _isOtpSent = true;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ─── Verify OTP ─────────────────────────────────────────────
  Future<bool> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      // ★ Capture existing verification state BEFORE _handleAuthResponse,
      // because the server's OTP-login response may not include the OTHER
      // verification flag, causing merge to reset it.
      final bool prevPhoneVerified = _currentUser?.isPhoneVerified ?? false;
      final String? prevPhone = _currentUser?.phoneNumber;
      final bool prevEmailVerified = _currentUser?.isEmailVerified ?? false;
      final String? prevEmail = _currentUser?.email;

      debugPrint('--- verifyOtp PRE-state ---');
      debugPrint('Phone: $prevPhone (verified: $prevPhoneVerified)');
      debugPrint('Email: $prevEmail (verified: $prevEmailVerified)');

      final request = OtpVerifyRequest(identifier: identifier, otp: otp);
      final response = await _authService.verifyOtp(request);
      await _handleAuthResponse(response);
      
      // Force-set verification status for both types, restoring any
      // flag that _handleAuthResponse may have lost.
      if (_currentUser != null) {
        UserModel updatedUser = _currentUser!;
        
        if (identifier.contains('@')) {
          // Email OTP — mark email verified, preserve phone state
          updatedUser = updatedUser.copyWith(
            isEmailVerified: true,
            email: identifier,
            isPhoneVerified: prevPhoneVerified || updatedUser.isPhoneVerified,
            phoneNumber: updatedUser.phoneNumber?.isNotEmpty == true
                ? updatedUser.phoneNumber
                : prevPhone,
          );
        } else {
          // Phone OTP — mark phone verified, preserve email state
          updatedUser = updatedUser.copyWith(
            isPhoneVerified: true,
            phoneNumber: identifier,
            isEmailVerified: prevEmailVerified || updatedUser.isEmailVerified,
            email: updatedUser.email.isNotEmpty ? updatedUser.email : (prevEmail ?? ''),
          );
        }

        debugPrint('--- verifyOtp POST-state (local) ---');
        debugPrint('Phone: ${updatedUser.phoneNumber} (verified: ${updatedUser.isPhoneVerified})');
        debugPrint('Email: ${updatedUser.email} (verified: ${updatedUser.isEmailVerified})');

        _currentUser = updatedUser;
        await _tokenStorage.saveUserData(updatedUser.toJson());

        // ★★ CRITICAL: Push the restored state back to the backend.
        // The auth/otp/login/ endpoint may have reset phone_number to null
        // in the database. We PATCH the correct data back immediately.
        if (_currentUser!.id != null) {
          final syncData = <String, dynamic>{};
          
          // Always include the email
          if (updatedUser.email.isNotEmpty) {
            syncData['email'] = updatedUser.email;
          }
          // Always include the phone number
          if (updatedUser.phoneNumber != null && updatedUser.phoneNumber!.isNotEmpty) {
            syncData['phone_number'] = updatedUser.phoneNumber;
          }

          if (syncData.isNotEmpty) {
            try {
              debugPrint('--- verifyOtp: syncing restored state to backend ---');
              debugPrint('Sync payload: $syncData');
              await _authService.updateProfileRaw(_currentUser!.id!, syncData);
              debugPrint('--- verifyOtp: backend sync complete ---');
            } catch (e) {
              debugPrint('⚠ Failed to sync restored state to backend: $e');
              // Non-fatal: local state is already correct
            }
          }
        }
      }

      _isOtpSent = false;
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ─── Google Auth ────────────────────────────────────────────
  Future<bool> googleLogin(String idToken) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _authService.googleAuth(idToken);
      await _handleAuthResponse(response);
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ─── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(true);
    try {
      final refreshToken = _tokenStorage.getRefreshToken();
      await _authService.logout(refreshToken: refreshToken);
    } catch (_) {
      // Logout should always clear local state even if API call fails
    }
    await _tokenStorage.clearAll();
    _currentUser = null;
    _isOtpSent = false;
    _setLoading(false);
  }

  // ─── Update Profile ──────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    _setError(null);
    try {
      // 1. Optimistically merge request data into current user state
      // We also include current verification flags to ensure they are sent to the backend
      final Map<String, dynamic> updateData = Map<String, dynamic>.from(data);
      if (_currentUser != null) {
        if (!updateData.containsKey('is_email_verified')) {
          updateData['is_email_verified'] = _currentUser!.isEmailVerified;
        }
        if (!updateData.containsKey('is_phone_verified')) {
          updateData['is_phone_verified'] = _currentUser!.isPhoneVerified;
        }
        if (!updateData.containsKey('phone_number') && _currentUser!.phoneNumber != null) {
          updateData['phone_number'] = _currentUser!.phoneNumber;
        }
        if (!updateData.containsKey('email') && _currentUser!.email.isNotEmpty) {
          updateData['email'] = _currentUser!.email;
        }
        _currentUser = UserModel.merge(_currentUser!, updateData);
      }

      // 2. Perform the actual API call
      debugPrint('--- AuthController.updateProfile ---');
      debugPrint('ID: ${_currentUser!.id}, Payload: $updateData');
      final responseData = await _authService.updateProfileRaw(_currentUser!.id!, updateData);
      debugPrint('Update Response Data: $responseData');
      
      // 3. Merge the actual server response (which might have extra fields like full_name)
      if (_currentUser != null) {
        _currentUser = UserModel.merge(_currentUser!, responseData);
        debugPrint('Post-Update Merge Local User: E=${_currentUser!.email}(V:${_currentUser!.isEmailVerified}), P=${_currentUser!.phoneNumber}(V:${_currentUser!.isPhoneVerified})');
      } else {
        _currentUser = UserModel.fromJson(responseData);
      }
      
      await _tokenStorage.saveUserData(_currentUser!.toJson());
      _setLoading(false); // Triggers notifyListeners()
      return true;
    } on DioException catch (e) {
      _setError(_extractError(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  // ─── Try Auto Login (check stored tokens on app start) ──────
  Future<bool> tryAutoLogin() async {
    final token = _tokenStorage.getAccessToken();
    if (token == null) return false;

    // Load from storage first for immediate UI update
    final userData = _tokenStorage.getUserData();
    bool loadedFromStorage = false;
    if (userData != null) {
      _currentUser = UserModel.fromJson(userData);
      notifyListeners();
      loadedFromStorage = true;
    }

    // Then fetch fresh data from API
    try {
      final freshUser = await _authService.getCurrentUser();
      if (_currentUser != null) {
        _currentUser = UserModel.merge(_currentUser!, freshUser.toJson());
      } else {
        _currentUser = freshUser;
      }
      await _tokenStorage.saveUserData(_currentUser!.toJson());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Auto-login refresh failed: $e');
      // If we loaded from storage, treat it as success even if API refresh fails (offline)
      return loadedFromStorage;
    }
  }

  // ─── Refresh Profile (fetch fresh user data from API) ───────
  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    try {
      // Capture current verification state before refresh
      final bool prevPhoneVerified = _currentUser!.isPhoneVerified;
      final String? prevPhone = _currentUser!.phoneNumber;
      final bool prevEmailVerified = _currentUser!.isEmailVerified;

      debugPrint('--- AuthController.refreshProfile ---');
      final freshUser = await _authService.getCurrentUser();
      debugPrint('Fresh User from API: ${freshUser.toJson()}');
      // Merge with existing user to preserve verification flags
      // that may not yet be reflected in the server response
      _currentUser = UserModel.merge(_currentUser!, freshUser.toJson());

      // ★ Safety net: never downgrade verification flags after refresh
      if (prevPhoneVerified && !_currentUser!.isPhoneVerified) {
        _currentUser = _currentUser!.copyWith(
          isPhoneVerified: true,
          phoneNumber: _currentUser!.phoneNumber ?? prevPhone,
        );
        debugPrint('⚠ Restored phone verification that was lost during refresh');
      }
      if (prevEmailVerified && !_currentUser!.isEmailVerified) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        debugPrint('⚠ Restored email verification that was lost during refresh');
      }

      debugPrint('Post-Refresh Local User: E=${_currentUser!.email}(V:${_currentUser!.isEmailVerified}), P=${_currentUser!.phoneNumber}(V:${_currentUser!.isPhoneVerified})');
      await _tokenStorage.saveUserData(_currentUser!.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh profile failed: $e');
    }
  }

  // ─── Reset OTP State ───────────────────────────────────────
  void resetOtpState() {
    _isOtpSent = false;
    notifyListeners();
  }
}
