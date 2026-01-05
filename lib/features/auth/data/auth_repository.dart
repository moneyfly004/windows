import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AuthRepository {
  TaskEither<AuthFailure, LoginResponse> login(String username, String password);
  TaskEither<AuthFailure, String> register(RegisterRequest request);
  TaskEither<AuthFailure, String> changePassword(ChangePasswordRequest request);
  TaskEither<AuthFailure, String> forgotPassword(String email);
  TaskEither<AuthFailure, String> resetPassword(
    String email,
    String code,
    String newPassword,
  );
  TaskEither<AuthFailure, String> sendVerificationCode(String email);
  TaskEither<AuthFailure, UserSubscription> getUserSubscription();
  TaskEither<AuthFailure, Unit> logout();
  bool isAuthenticated();
  String? getToken();
  UserInfo? getUser();
}

class AuthFailure {
  final String message;
  AuthFailure(this.message);
}

class AuthRepositoryImpl
    with ExceptionHandler, InfraLogger
    implements AuthRepository {
  AuthRepositoryImpl({
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;
  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dy.moneyfly.top/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  TaskEither<AuthFailure, LoginResponse> login(
    String username,
    String password,
  ) {
    return exceptionHandler(
      () async {
        try {
          final response = await _dio.post(
            '/auth/login-json',
            data: {
              'username': username,
              'password': password,
            },
          );

          if (response.data['success'] == true) {
            final data = response.data['data'] as Map<String, dynamic>;
            final loginResponse = LoginResponse(
              accessToken: data['access_token'] as String,
              refreshToken: data['refresh_token'] as String,
              user: UserInfo.fromJson(data['user'] as Map<String, dynamic>),
            );

            // 保存 token 和用户信息
            await sharedPreferences.setString(_tokenKey, loginResponse.accessToken);
            await sharedPreferences.setString(
              _refreshTokenKey,
              loginResponse.refreshToken,
            );
            await sharedPreferences.setString(
              _userKey,
              jsonEncode(loginResponse.user.toJson()),
            );

            loggy.info('登录成功: ${loginResponse.user.email}');
            return right(loginResponse);
          } else {
            final message = (response.data['message'] as String?) ?? '登录失败';
            loggy.error('登录失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('登录异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '登录失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('登录失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, String> register(RegisterRequest request) {
    return exceptionHandler(
      () async {
        try {
          final response = await _dio.post(
            '/auth/register',
            data: request.toJson(),
          );

          if (response.data['success'] == true) {
            final message = (response.data['message'] as String?) ?? '注册成功';
            loggy.info('注册成功: ${request.email}');
            return right(message);
          } else {
            final message = (response.data['message'] as String?) ?? '注册失败';
            loggy.error('注册失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('注册异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '注册失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('注册失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, String> changePassword(
    ChangePasswordRequest request,
  ) {
    return exceptionHandler(
      () async {
        try {
          final token = getToken();
          if (token == null) {
            return left(AuthFailure('未登录'));
          }

          final response = await _dio.post(
            '/users/change-password',
            data: request.toJson(),
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );

          if (response.data['success'] == true) {
            final message = (response.data['message'] as String?) ?? '密码修改成功';
            loggy.info('密码修改成功');
            return right(message);
          } else {
            final message = (response.data['message'] as String?) ?? '密码修改失败';
            loggy.error('密码修改失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('密码修改异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '密码修改失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('密码修改失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, String> forgotPassword(String email) {
    return exceptionHandler(
      () async {
        try {
          final response = await _dio.post(
            '/auth/forgot-password',
            data: {'email': email},
          );

          if (response.data['success'] == true) {
            final message = (response.data['message'] as String?) ?? '验证码已发送';
            loggy.info('忘记密码验证码已发送: $email');
            return right(message);
          } else {
            final message = (response.data['message'] as String?) ?? '发送失败';
            loggy.error('忘记密码验证码发送失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('忘记密码异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '发送失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('发送失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, String> resetPassword(
    String email,
    String code,
    String newPassword,
  ) {
    return exceptionHandler(
      () async {
        try {
          final response = await _dio.post(
            '/auth/reset-password',
            data: {
              'email': email,
              'verification_code': code,
              'new_password': newPassword,
            },
          );

          if (response.data['success'] == true) {
            final message = (response.data['message'] as String?) ?? '密码重置成功';
            loggy.info('密码重置成功: $email');
            return right(message);
          } else {
            final message = (response.data['message'] as String?) ?? '重置失败';
            loggy.error('密码重置失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('密码重置异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '重置失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('重置失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, String> sendVerificationCode(String email) {
    return exceptionHandler(
      () async {
        try {
          final response = await _dio.post(
            '/auth/verification/send',
            data: {
              'email': email,
              'type': 'email',
            },
          );

          if (response.data['success'] == true) {
            final message = (response.data['message'] as String?) ?? '验证码已发送';
            loggy.info('验证码已发送: $email');
            return right(message);
          } else {
            final message = (response.data['message'] as String?) ?? '发送失败';
            loggy.error('验证码发送失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('验证码发送异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '发送失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('发送失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, UserSubscription> getUserSubscription() {
    return exceptionHandler(
      () async {
        try {
          final token = getToken();
          if (token == null) {
            return left(AuthFailure('未登录'));
          }

          final response = await _dio.get(
            '/subscriptions/user-subscription',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );

          if (response.data['success'] == true) {
            final data = response.data['data'] as Map<String, dynamic>;
            final subscription = UserSubscription.fromJson(data);
            loggy.info('获取订阅成功: ${subscription.expireTime}');
            return right(subscription);
          } else {
            final message = (response.data['message'] as String?) ?? '获取订阅失败';
            loggy.error('获取订阅失败: $message');
            return left(AuthFailure(message));
          }
        } catch (e, stackTrace) {
          loggy.error('获取订阅异常', e, stackTrace);
          if (e is DioException) {
            final message = (e.response?.data['message'] as String?) ?? '获取订阅失败，请检查网络连接';
            return left(AuthFailure(message));
          }
          return left(AuthFailure('获取订阅失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  TaskEither<AuthFailure, Unit> logout() {
    return exceptionHandler(
      () async {
        try {
          final token = getToken();
          if (token != null) {
            try {
              await _dio.post(
                '/auth/logout',
                options: Options(
                  headers: {'Authorization': 'Bearer $token'},
                ),
              );
            } catch (e) {
              loggy.warning('登出API调用失败，但继续清除本地数据', e);
            }
          }

          await sharedPreferences.remove(_tokenKey);
          await sharedPreferences.remove(_refreshTokenKey);
          await sharedPreferences.remove(_userKey);

          loggy.info('用户已退出登录');
          return right(unit);
        } catch (e, stackTrace) {
          loggy.error('退出登录异常', e, stackTrace);
          return left(AuthFailure('退出登录失败: ${e.toString()}'));
        }
      },
      (error, stackTrace) => AuthFailure(error.toString()),
    );
  }

  @override
  bool isAuthenticated() {
    return getToken() != null;
  }

  @override
  String? getToken() {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  UserInfo? getUser() {
    final userJson = sharedPreferences.getString(_userKey);
    if (userJson == null) return null;
    try {
      return UserInfo.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (e) {
      loggy.error('解析用户信息失败', e);
      return null;
    }
  }
}

