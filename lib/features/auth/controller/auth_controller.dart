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
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final request = LoginRequest(email: email, phoneNumber: phoneNumber, password: password);
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
    String? email,
    String? phoneNumber,
    required String password,
    required String passwordConfirm,
    required String firstName,
    required String lastName,
    String? referralCode,
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
        referralCode: referralCode,
      );
      final response = await _authService.register(request);
      
      // If the registration response doesn't have tokens, we might need OTP login
      if (response.accessToken.isEmpty) {
        debugPrint('Registration successful but no tokens returned. Checking auto-login...');
        try {
          final loginResponse = await _authService.login(LoginRequest(
            email: email,
            phoneNumber: phoneNumber,
            password: password,
          ));
          await _handleAuthResponse(loginResponse);
        } catch (e) {
          debugPrint('Auto-login skipped (likely OTP-only system): $e');
          // We still return true because registration itself succeeded
        }
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
      // ── Preemptive Linking for Logged-In Users ──
      // If logged in, attempt to PATCH the identifier to the profile first.
      // This ensures the backend links the subsequent OTP login to the current session.
      if (_currentUser != null) {
        debugPrint('--- requestOtp: Logged in, patching identifier before OTP ---');
        final patchData = identifier.contains('@') 
            ? {'email': identifier} 
            : {'phone_number': identifier};
            
        try {
          // Sync with server immediately
          final responseData = await _authService.updateProfileRaw(_currentUser!.id!, patchData);
          _currentUser = UserModel.merge(_currentUser!, responseData);
          await _tokenStorage.saveUserData(_currentUser!.toJson());
          debugPrint('--- requestOtp: Preemptive PATCH successful ---');
        } catch (e) {
          debugPrint('--- requestOtp: Preemptive PATCH failed (likely already taken): $e ---');
          if (e is DioException && e.response?.statusCode == 400) {
            final errorData = e.response?.data;
            String msg = 'This ${identifier.contains('@') ? 'email' : 'phone number'} is already verified with another account.';
            if (errorData is Map && errorData.isNotEmpty) {
               msg = errorData.values.first.toString();
            }
            _setError(msg);
            _setLoading(false);
            return false;
          }
          // For other errors, we continue to requestOtp anyway
        }
      }

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
      final request = OtpVerifyRequest(identifier: identifier, otp: otp);
      final response = await _authService.verifyOtp(request);

      // ════════════════════════════════════════════════════════════
      // FLOW 1: LOGIN — no user is currently logged in.
      //   → Use the response normally (save tokens, set user).
      // ════════════════════════════════════════════════════════════
      if (_currentUser == null) {
        debugPrint('--- verifyOtp: LOGIN flow (no existing user) ---');
        await _handleAuthResponse(response);

        // Mark the verified identifier
        if (_currentUser != null) {
          if (identifier.contains('@')) {
            _currentUser = _currentUser!.copyWith(
              isEmailVerified: true,
              email: identifier,
            );
          } else {
            _currentUser = _currentUser!.copyWith(
              isPhoneVerified: true,
              phoneNumber: identifier,
            );
          }
          await _tokenStorage.saveUserData(_currentUser!.toJson());
        }

        _isOtpSent = false;
        _setLoading(false);
        return true;
      }

      // ════════════════════════════════════════════════════════════
      // FLOW 2: PROFILE VERIFICATION — user is already logged in.
      //   → The auth/otp/login/ request includes the auth header
      //     (added by ApiClient interceptor), so the backend
      //     verifies the phone/email for the CURRENT user.
      //   → Save the response tokens (they encode verified status).
      //   → Merge response user with current user to preserve data.
      //   → PATCH as a backup to update the user record.
      //   → Re-fetch profile to confirm backend state.
      // ════════════════════════════════════════════════════════════
      debugPrint('--- verifyOtp: PROFILE VERIFICATION flow ---');
      debugPrint('Current user ID: ${_currentUser!.id}');
      debugPrint('Response user ID: ${response.user?.id}');
      debugPrint('Identifier: $identifier');

      // ── Step 1: Check if the OTP response user matches the current user ──
      // Only save new tokens if IDs match — otherwise we'd switch sessions
      // and lose the cart / other user-specific data.
      final bool isSameUser = response.user != null && 
          response.user!.id == _currentUser!.id;

      if (isSameUser && response.accessToken.isNotEmpty) {
        // Same user — save the new tokens (they encode verified status)
        await _tokenStorage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        // Merge the response user data
        _currentUser = UserModel.merge(_currentUser!, 
          response.rawUserJson ?? response.user!.toJson());
        debugPrint('--- verifyOtp: Same user — saved new tokens & merged ---');
      } else {
        debugPrint('--- verifyOtp: Different user (${response.user?.id}) or no user in response — keeping original tokens ---');
      }

      // ── Step 3: PATCH to update phone/email on the current user record ──
      // This is necessary because 'auth/otp/login/' doesn't always 
      // link the phone if the current session is different.
      final patchData = <String, dynamic>{};
      if (identifier.contains('@')) {
        patchData['email'] = identifier;
      } else {
        patchData['phone_number'] = identifier;
      }

      debugPrint('--- verifyOtp: PATCHing current user ${_currentUser!.id} ---');
      try {
        final responseData = await _authService.updateProfileRaw(
          _currentUser!.id!,
          patchData,
        );
        debugPrint('--- verifyOtp: PATCH response was successful ---');
        _currentUser = UserModel.merge(_currentUser!, responseData);
      } catch (patchErr) {
        debugPrint('⚠ PATCH failed: $patchErr — the phone may be linked to another account');
      }

      // ── Step 4: Re-fetch user profile to confirm backend state ──
      // This is the source of truth. If the backend didn't set is_phone_verified=true
      // (because it's read-only or because the PATCH failed), we must reflect that.
      try {
        final freshUser = await _authService.getCurrentUser();
        _currentUser = UserModel.merge(_currentUser!, freshUser.toJson());
        await _tokenStorage.saveUserData(_currentUser!.toJson());
        debugPrint('--- verifyOtp: Profile re-fetched and synced ---');
      } catch (fetchErr) {
        debugPrint('⚠ Profile re-fetch after verification failed: $fetchErr');
      }

      debugPrint('--- verifyOtp FINAL state ---');
      debugPrint('Phone: ${_currentUser!.phoneNumber} (verified: ${_currentUser!.isPhoneVerified})');
      debugPrint('Email: ${_currentUser!.email} (verified: ${_currentUser!.isEmailVerified})');

      // Check if the requested verification actually happened on the backend for this user
      final bool emailRequest = identifier.contains('@');
      final bool nowVerified = emailRequest ? _currentUser!.isEmailVerified : _currentUser!.isPhoneVerified;

      if (!nowVerified) {
        debugPrint('--- verifyOtp: Logical verification failure (not updated on backend) ---');
        _setError(emailRequest 
          ? 'Failed to verify email. Please try again.' 
          : 'This phone number is already verified with another account.');
        _setLoading(false);
        return false;
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
        // Capture state before merge for safety net
        final bool preEmailV = _currentUser!.isEmailVerified;
        final bool prePhoneV = _currentUser!.isPhoneVerified;

        _currentUser = UserModel.merge(_currentUser!, responseData);

        // Safety net: don't downgrade verification if identifiers didn't change
        if (preEmailV && !_currentUser!.isEmailVerified) {
          _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        }
        if (prePhoneV && !_currentUser!.isPhoneVerified) {
          _currentUser = _currentUser!.copyWith(isPhoneVerified: true);
        }

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
