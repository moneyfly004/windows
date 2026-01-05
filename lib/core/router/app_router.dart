import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/deep_link/notifier/deep_link_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'app_router.g.dart';

bool _debugMobileRouter = false;

final useMobileRouter = !PlatformUtils.isDesktop || (kDebugMode && _debugMobileRouter);
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// TODO: test and improve handling of deep link
@riverpod
GoRouter router(RouterRef ref) {
  final notifier = ref.watch(routerListenableProvider.notifier);
  final deepLink = ref.listen(
    deepLinkNotifierProvider,
    (_, next) async {
      if (next case AsyncData(value: final link?)) {
        await ref.state.push(AddProfileRoute(url: link.url).location);
      }
    },
  );
  final initialLink = deepLink.read();
  // 默认初始位置为登录页，redirect 方法会根据登录状态决定跳转
  String initialLocation = const LoginRoute().location;
  if (initialLink case AsyncData(value: final link?)) {
    initialLocation = AddProfileRoute(url: link.url).location;
  }

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    routes: [
      if (useMobileRouter) $mobileWrapperRoute else $desktopWrapperRoute,
      $introRoute,
      $loginRoute,
      $registerRoute,
      $forgotPasswordRoute,
      $changePasswordRoute,
      $packagesRoute,
      // PaymentRoute 需要手动处理
    ],
    refreshListenable: notifier,
    redirect: notifier.redirect,
    observers: [
      SentryNavigatorObserver(),
    ],
  );
}

final tabLocations = [
  const HomeRoute().location,
  const ProxiesRoute().location,
  const ConfigOptionsRoute().location,
  const SettingsRoute().location,
  const LogsOverviewRoute().location,
  const AboutRoute().location,
];

int getCurrentIndex(BuildContext context) {
  final String location = GoRouterState.of(context).uri.path;
  if (location == const HomeRoute().location) return 0;
  var index = 0;
  for (final tab in tabLocations.sublist(1)) {
    index++;
    if (location.startsWith(tab)) return index;
  }
  return 0;
}

void switchTab(int index, BuildContext context) {
  assert(index >= 0 && index < tabLocations.length);
  final location = tabLocations[index];
  return context.go(location);
}

@riverpod
class RouterListenable extends _$RouterListenable with AppLogger implements Listenable {
  VoidCallback? _routerListener;
  bool _introCompleted = false;

  @override
  Future<void> build() async {
    _introCompleted = ref.watch(Preferences.introCompleted);

    ref.listenSelf((_, __) {
      if (state.isLoading) return;
      loggy.debug("triggering listener");
      _routerListener?.call();
    });
  }

// ignore: avoid_build_context_in_providers
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    // if (this.state.isLoading || this.state.hasError) return null;

    final isIntro = state.uri.path == const IntroRoute().location;
    final isLogin = state.uri.path == const LoginRoute().location;
    final isRegister = state.uri.path == const RegisterRoute().location;
    final isForgotPassword = state.uri.path == const ForgotPasswordRoute().location;
    final isChangePassword = state.uri.path == const ChangePasswordRoute().location;
    final isPackages = state.uri.path == const PackagesRoute().location;

    // 认证相关页面和套餐购买页面不需要检查登录状态（套餐购买页面内部会检查）
    if (isLogin || isRegister || isForgotPassword || isChangePassword || isPackages) {
      return null;
    }

    if (!_introCompleted) {
      return const IntroRoute().location;
    } else if (isIntro) {
      // 介绍页完成后，检查登录状态
      try {
        final authRepo = await ref.read(authRepositoryProvider.future);
        if (authRepo.isAuthenticated()) {
          return const HomeRoute().location;
        } else {
          return const LoginRoute().location;
        }
      } catch (e) {
        return const LoginRoute().location;
      }
    }

    // 检查登录状态
    try {
      final authRepo = await ref.read(authRepositoryProvider.future);
      if (!authRepo.isAuthenticated()) {
        // 未登录，重定向到登录页
        return const LoginRoute().location;
      }
    } catch (e) {
      // 如果检查失败，也重定向到登录页
      return const LoginRoute().location;
    }

    return null;
  }

  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }
}
