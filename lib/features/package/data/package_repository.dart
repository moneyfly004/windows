import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/utils/exception_handler.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/package/model/package_models.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PackageRepository {
  TaskEither<PackageFailure, List<Package>> getPackages();
  TaskEither<PackageFailure, Order> createOrder(CreateOrderRequest request);
  TaskEither<PackageFailure, Order> getOrderStatus(String orderNo);
}

class PackageFailure {
  final String message;
  PackageFailure(this.message);
}

class PackageRepositoryImpl
    with ExceptionHandler, InfraLogger
    implements PackageRepository {
  PackageRepositoryImpl({
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;
  late final Dio _dio = Dio(
    BaseOptions(
      baseURL: 'https://dy.moneyfly.top/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  String? _getToken() {
    return sharedPreferences.getString('auth_token');
  }

  @override
  TaskEither<PackageFailure, List<Package>> getPackages() {
    return exceptionHandler(
      () async {
        try {
          final response = await _dio.get('/packages');

          if (response.data['success'] == true) {
            final data = response.data['data'] as List;
            final packages = data
                .map((json) => Package.fromJson(json as Map<String, dynamic>))
                .toList();
            loggy.info('获取套餐列表成功: ${packages.length} 个套餐');
            return right(packages);
          } else {
            final message = response.data['message'] ?? '获取套餐列表失败';
            loggy.error('获取套餐列表失败: $message');
            return left(PackageFailure(message));
          }
        } catch (e) {
          loggy.error('获取套餐列表异常', e);
          if (e is DioException) {
            final message = e.response?.data['message'] ?? '获取套餐列表失败，请检查网络连接';
            return left(PackageFailure(message));
          }
          return left(PackageFailure('获取套餐列表失败: ${e.toString()}'));
        }
      },
      (error) => PackageFailure(error.toString()),
    );
  }

  @override
  TaskEither<PackageFailure, Order> createOrder(CreateOrderRequest request) {
    return exceptionHandler(
      () async {
        try {
          final token = _getToken();
          if (token == null) {
            return left(PackageFailure('未登录'));
          }

          final response = await _dio.post(
            '/orders',
            data: request.toJson(),
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );

          if (response.data['success'] == true) {
            final data = response.data['data'];
            final order = Order.fromJson(data as Map<String, dynamic>);
            loggy.info('创建订单成功: ${order.orderNo}');
            return right(order);
          } else {
            final message = response.data['message'] ?? '创建订单失败';
            loggy.error('创建订单失败: $message');
            return left(PackageFailure(message));
          }
        } catch (e) {
          loggy.error('创建订单异常', e);
          if (e is DioException) {
            final message = e.response?.data['message'] ?? '创建订单失败，请检查网络连接';
            return left(PackageFailure(message));
          }
          return left(PackageFailure('创建订单失败: ${e.toString()}'));
        }
      },
      (error) => PackageFailure(error.toString()),
    );
  }

  @override
  TaskEither<PackageFailure, Order> getOrderStatus(String orderNo) {
    return exceptionHandler(
      () async {
        try {
          final token = _getToken();
          if (token == null) {
            return left(PackageFailure('未登录'));
          }

          final response = await _dio.get(
            '/orders/$orderNo/status',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );

          if (response.data['success'] == true) {
            final data = response.data['data'];
            final order = Order.fromJson(data as Map<String, dynamic>);
            loggy.info('查询订单状态成功: ${order.orderNo} - ${order.status}');
            return right(order);
          } else {
            final message = response.data['message'] ?? '查询订单状态失败';
            loggy.error('查询订单状态失败: $message');
            return left(PackageFailure(message));
          }
        } catch (e) {
          loggy.error('查询订单状态异常', e);
          if (e is DioException) {
            final message = e.response?.data['message'] ?? '查询订单状态失败，请检查网络连接';
            return left(PackageFailure(message));
          }
          return left(PackageFailure('查询订单状态失败: ${e.toString()}'));
        }
      },
      (error) => PackageFailure(error.toString()),
    );
  }
}

