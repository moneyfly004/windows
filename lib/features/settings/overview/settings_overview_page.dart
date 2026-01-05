import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/settings/about/about_page.dart';
import 'package:hiddify/features/settings/widgets/widgets.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsOverviewPage extends HookConsumerWidget {
  const SettingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isAuthenticatedAsync = ref.watch(isAuthenticatedProvider);
    // 正确处理异步认证状态：等待加载完成后再判断
    final isAuthenticated = isAuthenticatedAsync.when(
      data: (value) => value,
      loading: () => false, // 加载中时先不显示，避免闪烁
      error: (_, __) => false, // 出错时也不显示
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          NestedAppBar(
            title: Text(t.settings.pageTitle),
          ),
          SliverList.list(
            children: [
              SettingsSection(t.settings.general.sectionTitle),
              const GeneralSettingTiles(),
              const PlatformSettingsTiles(),
              const SettingsDivider(),
              SettingsSection(t.settings.advanced.sectionTitle),
              const AdvancedSettingTiles(),
              const SettingsDivider(),
              // 套餐购买（放在关于上面）
              if (isAuthenticated) ...[
                ListTile(
                  leading: Icon(FluentIcons.cart_24_regular),
                  title: const Text('套餐购买'),
                  trailing: const Icon(FluentIcons.chevron_right_24_regular),
                  onTap: () {
                    const PackagesRoute().push(context);
                  },
                ),
                const SettingsDivider(),
              ],
              // 关于
              ListTile(
                leading: const Icon(FluentIcons.info_24_regular),
                title: Text(t.about.pageTitle),
                trailing: const Icon(FluentIcons.chevron_right_24_regular),
                onTap: () {
                  const AboutRoute().push(context);
                },
              ),
              // 修改密码
              if (isAuthenticated) ...[
                const SettingsDivider(),
                ListTile(
                  leading: Icon(FluentIcons.key_24_regular),
                  title: const Text('修改密码'),
                  trailing: const Icon(FluentIcons.chevron_right_24_regular),
                  onTap: () {
                    const ChangePasswordRoute().push(context);
                  },
                ),
              ],
              // 退出登录（放在修改密码下面）
              if (isAuthenticated) ...[
                const SettingsDivider(),
                ListTile(
                  leading: const Icon(FluentIcons.sign_out_24_regular),
                  title: const Text('退出登录'),
                  onTap: () async {
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
                  },
                ),
              ],
              const Gap(16),
            ],
          ),
        ],
      ),
    );
  }
}
