import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio dio;
  
  // Set fallback backend URL (localhost for emulator, render in production)
  static final String _baseUrl = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
      ? 'http://10.0.2.2:5000/api'  // Android Emulator loopback
      : 'http://localhost:5000/api'; // iOS/Web/Desktop loopback

  // Used for development when Firebase is bypassed
  static String mockEmail = "mock_user";

  ApiClient() : dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    // Add auth interceptor to append Firebase Token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            // Fallback mock token for development mode
            options.headers['Authorization'] = 'Bearer mock_$mockEmail';
          }
        } catch (e) {
          // If Firebase is not initialized, inject mock token
          options.headers['Authorization'] = 'Bearer mock_$mockEmail';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Centralized API error logger
        debugPrint("API Error [${e.response?.statusCode}]: ${e.message}");
        return handler.next(e);
      },
    ));
  }

  // HTTP Helper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }
}
