import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) => Breakpoints.small.isActive(context);
}

class AdaptiveRootScaffold extends HookConsumerWidget {
  const AdaptiveRootScaffold(this.navigator, {super.key});

  final Widget navigator;

  int _getSelectedIndex(BuildContext context, bool isAuthenticated) {
    final String location = GoRouterState.of(context).uri.path;

    // 基础路由映射（使用 startsWith 以支持子路由）
    if (location.startsWith(const ConfigOptionsRoute().location)) return 0;
    if (location.startsWith(const SettingsRoute().location)) return 1;
    if (location.startsWith(const LogsOverviewRoute().location)) return 2;

    // 认证相关路由（仅在登录时）
    if (isAuthenticated) {
      if (location.startsWith(const PackagesRoute().location)) return 3;
      if (location.startsWith(const ChangePasswordRoute().location)) return 4;
      if (location.startsWith(const AboutRoute().location)) return 5;
    } else {
      if (location.startsWith(const AboutRoute().location)) return 3;
    }

    return 0; // 默认返回第一个
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isAuthenticatedAsync = ref.watch(isAuthenticatedProvider);
    final isAuthenticated = isAuthenticatedAsync.when(
      data: (value) => value ?? false,
      loading: () => false,
      error: (_, __) => false,
    );

    final selectedIndex = _getSelectedIndex(context, isAuthenticated);

    // 基础菜单项：配置选项、设置、日志、关于
    final baseDestinations = [
      NavigationDestination(
        icon: const Icon(FluentIcons.box_edit_20_filled),
        label: t.config.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_20_filled),
        label: t.settings.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.document_text_20_filled),
        label: t.logs.pageTitle,
      ),
    ];

    // 如果已登录，添加认证相关菜单项
    final authDestinations = isAuthenticated
        ? [
            NavigationDestination(
              icon: const Icon(FluentIcons.cart_20_filled),
              label: '套餐购买',
            ),
            NavigationDestination(
              icon: const Icon(FluentIcons.key_20_filled),
              label: '修改密码',
            ),
          ]
        : <NavigationDestination>[];

    // 关于菜单项
    final aboutDestination = NavigationDestination(
      icon: const Icon(FluentIcons.info_20_filled),
      label: t.about.pageTitle,
    );

    // 如果已登录，添加退出登录菜单项
    final logoutDestination = isAuthenticated
        ? NavigationDestination(
            icon: const Icon(FluentIcons.sign_out_20_filled),
            label: '退出登录',
          )
        : null;

    // 组合所有菜单项
    final destinations = [
      ...baseDestinations,
      ...authDestinations,
      aboutDestination,
      if (logoutDestination != null) logoutDestination,
    ];

    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        RootScaffold.stateKey.currentState?.closeDrawer();
        _handleMenuSelection(index, context, ref, isAuthenticated);
      },
      destinations: destinations,
      drawerDestinationRange: useMobileRouter ? (0, null) : (0, null),
      bottomDestinationRange: (0, 2),
      useBottomSheet: useMobileRouter,
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SideBarStatsOverview(),
        ),
      ),
      body: navigator,
    );
  }

  void _handleMenuSelection(
    int index,
    BuildContext context,
    WidgetRef ref,
    bool isAuthenticated,
  ) {
    // 菜单项顺序：配置选项(0), 设置(1), 日志(2), 套餐购买(3), 修改密码(4), 关于(5), 退出登录(6)
    switch (index) {
      case 0:
        const ConfigOptionsRoute().go(context);
        break;
      case 1:
        const SettingsRoute().go(context);
        break;
      case 2:
        const LogsOverviewRoute().go(context);
        break;
      case 3:
        if (isAuthenticated) {
          const PackagesRoute().push(context);
        } else {
          // 如果未登录，这个索引可能是关于
          const AboutRoute().go(context);
        }
        break;
      case 4:
        if (isAuthenticated) {
          const ChangePasswordRoute().push(context);
        } else {
          // 如果未登录，这个索引是关于
          const AboutRoute().go(context);
        }
        break;
      case 5:
        if (isAuthenticated) {
          const AboutRoute().go(context);
        } else {
          // 如果未登录，这个索引不存在
        }
        break;
      case 6:
        if (isAuthenticated) {
          // 退出登录
          _handleLogout(context, ref);
        }
        break;
      default:
        break;
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = await ref.read(authRepositoryProvider.future);
        final result = await repository.logout().run();

        result.fold(
          (failure) {
            if (context.mounted) {
              showToast(
                context,
                failure.message,
                type: ToastType.error,
              );
            }
          },
          (_) {
            // 刷新认证状态
            ref.invalidate(isAuthenticatedProvider);
            if (context.mounted) {
              showToast(
                context,
                '已退出登录',
                type: ToastType.success,
              );
              // 跳转到登录页
              const LoginRoute().go(context);
            }
          },
        );
      } catch (e) {
        if (context.mounted) {
          showToast(
            context,
            '退出登录失败: $e',
            type: ToastType.error,
          );
        }
      }
    }
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget {
  const _CustomAdaptiveScaffold({
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    required this.drawerDestinationRange,
    required this.bottomDestinationRange,
    this.useBottomSheet = false,
    this.sidebarTrailing,
    required this.body,
  });

  final int selectedIndex;
  final Function(int) onSelectedIndexChange;
  final List<NavigationDestination> destinations;
  final (int, int?) drawerDestinationRange;
  final (int, int?) bottomDestinationRange;
  final bool useBottomSheet;
  final Widget? sidebarTrailing;
  final Widget body;

  List<NavigationDestination> destinationsSlice((int, int?) range) => destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1)) ? null : index;
  }

  void selectWithOffset(int index, (int, int?) range) => onSelectedIndexChange(index + range.$1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: RootScaffold.stateKey,
      drawer: Breakpoints.small.isActive(context)
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedWithOffset(drawerDestinationRange),
                destinations: destinationsSlice(drawerDestinationRange).map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: (index) => selectWithOffset(index, drawerDestinationRange),
              ),
            )
          : null,
      body: AdaptiveLayout(
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                selectedIndex: selectedIndex,
                destinations: destinations.map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: onSelectedIndexChange,
              ),
            ),
            Breakpoints.large: SlotLayout.from(
              key: const Key('primaryNavigation1'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                destinations: destinations.map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: onSelectedIndexChange,
                trailing: sidebarTrailing,
              ),
            ),
          },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              inAnimation: AdaptiveScaffold.fadeIn,
              outAnimation: AdaptiveScaffold.fadeOut,
              builder: (context) => body,
            ),
          },
        ),
      ),
      // AdaptiveLayout bottom sheet has accessibility issues
      bottomNavigationBar: useBottomSheet && Breakpoints.small.isActive(context)
          ? NavigationBar(
              selectedIndex: selectedWithOffset(bottomDestinationRange) ?? 0,
              destinations: destinationsSlice(bottomDestinationRange),
              onDestinationSelected: (index) => selectWithOffset(index, bottomDestinationRange),
            )
          : null,
    );
  }
}
