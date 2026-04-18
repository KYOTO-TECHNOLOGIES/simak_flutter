import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uae_ecom_project/core/network/api_client.dart';
import 'package:uae_ecom_project/features/auth/model/auth_response_model.dart';
import 'package:uae_ecom_project/features/auth/model/login_model.dart';
import 'package:uae_ecom_project/features/auth/model/otp_model.dart';
import 'package:uae_ecom_project/features/auth/model/register_model.dart';
import 'package:uae_ecom_project/features/auth/model/user_model.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  // ─── Email / Password Login ─────────────────────────────────
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dio.post(
      'auth/login/',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Register ───────────────────────────────────────────────
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dio.post(
      'users/',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Request OTP ────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtp(OtpRequestModel request) async {
    final response = await _dio.post(
      'auth/otp/request/',
      data: request.toJson(),
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Verify OTP & Login ─────────────────────────────────────
  Future<AuthResponse> verifyOtp(OtpVerifyRequest request) async {
    final response = await _dio.post(
      'auth/otp/login/',
      data: request.toJson(),
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Google Auth ────────────────────────────────────────────
  Future<AuthResponse> googleAuth(String token) async {
    final response = await _dio.post(
      'auth/google/callback/',
      data: {'code': token},
    );
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Get Current User Profile ───────────────────────────────
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get('users/me/');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ─── Logout ─────────────────────────────────────────────────
  Future<void> logout({String? refreshToken}) async {
    await _dio.post(
      'auth/logout/',
      data: refreshToken != null ? {'refresh': refreshToken} : null,
    );
  }

  // ─── Update Profile ──────────────────────────────────────────
  Future<UserModel> updateProfile(int userId, Map<String, dynamic> data) async {
    final responseData = await updateProfileRaw(userId, data);
    return UserModel.fromJson(responseData);
  }

  Future<Map<String, dynamic>> updateProfileRaw(int userId, Map<String, dynamic> data) async {
    final response = await _dio.patch(
      'users/$userId/',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ─── Update Profile Image ────────────────────────────────────
  Future<Map<String, dynamic>> updateProfileImage(int userId, File imageFile) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'profile.profile_picture': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });

    final response = await _dio.patch(
      'users/$userId/',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}
