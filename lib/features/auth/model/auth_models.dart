import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String username,
    required String email,
    required String password,
    String? verificationCode,
    String? inviteCode,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
class ChangePasswordRequest with _$ChangePasswordRequest {
  const factory ChangePasswordRequest({
    required String oldPassword,
    required String newPassword,
  }) = _ChangePasswordRequest;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
}

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String accessToken,
    required String refreshToken,
    required UserInfo user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
class UserInfo with _$UserInfo {
  const factory UserInfo({
    required int id,
    required String username,
    required String email,
    @Default(false) bool isAdmin,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);
}

@freezed
class UserSubscription with _$UserSubscription {
  const factory UserSubscription({
    @Default('') String universalUrl,
    String? subscriptionUrl,
    @Default('') String expireTime,
    @Default(0) int deviceLimit,
    @Default(0) int currentDevices,
    @Default(0) int uploadTraffic,
    @Default(0) int downloadTraffic,
    @Default(0) int totalTraffic,
  }) = _UserSubscription;

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionFromJson(json);
}

// ApiResponse 不需要序列化，只在内部使用
// @freezed
// class ApiResponse<T> with _$ApiResponse<T> {
//   const factory ApiResponse({
//     required bool success,
//     required String message,
//     T? data,
//   }) = _ApiResponse<T>;
//
//   factory ApiResponse.fromJson(
//     Map<String, dynamic> json,
//     T Function(Object?) fromJsonT,
//   ) =>
//       _$ApiResponseFromJson(json, fromJsonT);
// }

