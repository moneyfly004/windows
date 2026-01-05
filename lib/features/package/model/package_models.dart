import 'package:freezed_annotation/freezed_annotation.dart';

part 'package_models.freezed.dart';
part 'package_models.g.dart';

@freezed
class Package with _$Package {
  const factory Package({
    required int id,
    required String name,
    String? description,
    required double price,
    @JsonKey(name: 'duration_days') required int durationDays,
    @JsonKey(name: 'device_limit') required int deviceLimit,
    @JsonKey(name: 'is_recommended') @Default(false) bool isRecommended,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Package;

  factory Package.fromJson(Map<String, dynamic> json) =>
      _$PackageFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required int id,
    @JsonKey(name: 'order_no') required String orderNo,
    @JsonKey(name: 'package_id') required int packageId,
    required double amount,
    @JsonKey(name: 'final_amount') double? finalAmount,
    @JsonKey(name: 'discount_amount') double? discountAmount,
    required String status,
    @JsonKey(name: 'payment_url') String? paymentUrl,
    @JsonKey(name: 'payment_qr_code') String? paymentQrCode,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

@freezed
class CreateOrderRequest with _$CreateOrderRequest {
  const factory CreateOrderRequest({
    @JsonKey(name: 'package_id') required int packageId,
    @JsonKey(name: 'payment_method') @Default('alipay') String paymentMethod,
    @JsonKey(name: 'coupon_code') String? couponCode,
    @JsonKey(name: 'use_balance') @Default(false) bool useBalance,
    @JsonKey(name: 'balance_amount') @Default(0.0) double balanceAmount,
    @Default('CNY') String currency,
  }) = _CreateOrderRequest;

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestFromJson(json);
}

extension CreateOrderRequestExtension on CreateOrderRequest {
  Map<String, dynamic> toJson() {
    return {
      'package_id': packageId,
      'payment_method': paymentMethod,
      if (couponCode != null) 'coupon_code': couponCode,
      'use_balance': useBalance,
      'balance_amount': balanceAmount,
      'currency': currency,
    };
  }
}

