import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/notifier/subscription_update_notifier.dart';
import 'package:hiddify/features/auth/ui/register_page.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class LoginPage extends HookConsumerWidget with AppLogger {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final obscurePassword = useState(true);

    // 检查是否已登录
    useEffect(() {
      Future.microtask(() async {
        try {
          final repository = await ref.read(authRepositoryProvider.future);
          if (repository.isAuthenticated()) {
            if (context.mounted) {
              const HomeRoute().go(context);
            }
          }
        } catch (e) {
          // 忽略错误，继续显示登录页面
        }
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Gap(32),
                  Text(
                    '欢迎回来',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    '请登录您的账号',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(32),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名或邮箱',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名或邮箱';
                      }
                      return null;
                    },
                    enabled: !isLoading.value,
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          obscurePassword.value = !obscurePassword.value;
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: obscurePassword.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 8) {
                        return '密码至少8位';
                      }
                      return null;
                    },
                    enabled: !isLoading.value,
                  ),
                  const Gap(8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () {
                              const ForgotPasswordRoute().push(context);
                            },
                      child: const Text('忘记密码？'),
                    ),
                  ),
                  const Gap(24),
                  FilledButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              isLoading.value = true;
                              try {
                                final repository = await ref.read(authRepositoryProvider.future);
                                final result = await repository
                                    .login(
                                      usernameController.text.trim(),
                                      passwordController.text,
                                    )
                                    .run();

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
                                  (response) async {
                                    // 登录成功后获取订阅
                                    final subscriptionResult = await repository.getUserSubscription().run();

                                    subscriptionResult.fold(
                                      (failure) {
                                        if (context.mounted) {
                                          showToast(
                                            context,
                                            '登录成功，但获取订阅失败: ${failure.message}',
                                            type: ToastType.warning,
                                          );
                                          // 刷新认证状态
                                          ref.invalidate(isAuthenticatedProvider);
                                          // 导航到主页
                                          const HomeRoute().go(context);
                                        }
                                      },
                                      (subscription) async {
                                        // 自动添加订阅到配置
                                        if (subscription.universalUrl.isNotEmpty) {
                                          try {
                                            final profileRepository = await ref.read(profileRepositoryProvider.future);

                                            // 获取所有配置，查找旧的订阅配置
                                            final allProfilesResult = await profileRepository.watchAll().first;

                                            allProfilesResult.fold(
                                              (failure) {
                                                loggy.warning('获取配置列表失败', failure);
                                              },
                                              (profiles) async {
                                                RemoteProfileEntity? existingProfileWithSameUrl;
                                                final List<RemoteProfileEntity> oldSubscriptionProfiles = [];

                                                // 查找与新订阅 URL 相同的配置，以及所有旧的订阅配置
                                                for (final profile in profiles) {
                                                  profile.maybeWhen(
                                                    remote: (id, active, name, url, lastUpdate, testUrl, options, subInfo) {
                                                      if (url == subscription.universalUrl) {
                                                        // 找到相同 URL 的配置
                                                        existingProfileWithSameUrl = profile as RemoteProfileEntity;
                                                      } else if (name.contains('到期:') || name.contains('订阅配置')) {
                                                        // 可能是旧的订阅配置（通过名称判断）
                                                        oldSubscriptionProfiles.add(profile as RemoteProfileEntity);
                                                      }
                                                    },
                                                    orElse: () {},
                                                  );
                                                }

                                                // 删除旧的订阅配置（与新订阅 URL 不同的）
                                                for (final oldProfile in oldSubscriptionProfiles) {
                                                  if (oldProfile.url != subscription.universalUrl) {
                                                    loggy.info('删除旧订阅配置: ${oldProfile.name} (${oldProfile.url})');
                                                    await profileRepository.deleteById(oldProfile.id).run();
                                                  }
                                                }

                                                // 格式化到期时间作为配置名称
                                                String profileName = '订阅配置';
                                                try {
                                                  final expireDate = DateTime.parse(subscription.expireTime);
                                                  profileName = '到期: ${DateFormat('yyyy-MM-dd HH:mm').format(expireDate)}';
                                                } catch (e) {
                                                  profileName = '到期: ${subscription.expireTime}';
                                                }

                                                final existingProfile = existingProfileWithSameUrl;
                                                if (existingProfile != null) {
                                                  // 如果存在相同 URL 的配置，更新它
                                                  loggy.info('更新现有订阅配置: ${existingProfile.name}');
                                                  final profileToUpdate = existingProfile.copyWith(
                                                    active: true,
                                                    name: profileName,
                                                  );
                                                  final updateResult = await profileRepository
                                                      .updateSubscription(
                                                        profileToUpdate,
                                                        patchBaseProfile: true,
                                                      )
                                                      .run();

                                                  updateResult.fold(
                                                    (failure) {
                                                      if (context.mounted) {
                                                        final t = ref.read(translationsProvider);
                                                        final failureInfo = failure.present(t);
                                                        showToast(
                                                          context,
                                                          '订阅更新失败: ${failureInfo.message ?? failureInfo.type}',
                                                          type: ToastType.error,
                                                        );
                                                      }
                                                    },
                                                    (_) {
                                                      if (context.mounted) {
                                                        showToast(
                                                          context,
                                                          '订阅已更新',
                                                          type: ToastType.success,
                                                        );
                                                      }
                                                    },
                                                  );
                                                } else {
                                                  // 如果不存在相同 URL 的配置，添加新的
                                                  loggy.info('添加新订阅配置: $profileName');
                                                  final addResult = await profileRepository
                                                      .addByUrl(
                                                        subscription.universalUrl,
                                                        markAsActive: true,
                                                      )
                                                      .run();

                                                  addResult.fold(
                                                    (failure) {
                                                      if (context.mounted) {
                                                        final t = ref.read(translationsProvider);
                                                        final failureInfo = failure.present(t);
                                                        showToast(
                                                          context,
                                                          '订阅添加失败: ${failureInfo.message ?? failureInfo.type}',
                                                          type: ToastType.error,
                                                        );
                                                      }
                                                    },
                                                    (_) async {
                                                      // 更新配置名称为到期时间
                                                      try {
                                                        final allProfiles = await profileRepository.watchAll().first;
                                                        allProfiles.fold(
                                                          (failure) {},
                                                          (profiles) async {
                                                            for (final profile in profiles) {
                                                              profile.maybeWhen(
                                                                remote: (id, active, name, url, lastUpdate, testUrl, options, subInfo) async {
                                                                  if (url == subscription.universalUrl) {
                                                                    final updatedProfile = profile.copyWith(name: profileName);
                                                                    await profileRepository.patch(updatedProfile).run();
                                                                    return;
                                                                  }
                                                                },
                                                                orElse: () {},
                                                              );
                                                            }
                                                          },
                                                        );
                                                      } catch (e) {
                                                        loggy.warning('更新配置名称失败', e);
                                                      }

                                                      if (context.mounted) {
                                                        showToast(
                                                          context,
                                                          '订阅已自动添加',
                                                          type: ToastType.success,
                                                        );
                                                      }
                                                    },
                                                  );
                                                }
                                              },
                                            );
                                          } catch (e) {
                                            if (context.mounted) {
                                              showToast(
                                                context,
                                                '添加订阅时出错: $e',
                                                type: ToastType.error,
                                              );
                                            }
                                          }
                                        }

                                        if (context.mounted) {
                                          showToast(
                                            context,
                                            '登录成功',
                                            type: ToastType.success,
                                          );
                                          // 刷新认证状态
                                          ref.invalidate(isAuthenticatedProvider);
                                          // 触发订阅更新（异步执行，不阻塞导航）
                                          Future.microtask(() {
                                            ref.read(subscriptionUpdateNotifierProvider.notifier).updateSubscription();
                                          });
                                          // 导航到主页
                                          const HomeRoute().go(context);
                                        }
                                      },
                                    );
                                  },
                                );
                              } finally {
                                if (context.mounted) {
                                  isLoading.value = false;
                                }
                              }
                            }
                          },
                    child: isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('登录'),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('还没有账号？'),
                      TextButton(
                        onPressed: isLoading.value
                            ? null
                            : () {
                                const RegisterRoute().push(context);
                              },
                        child: const Text('立即注册'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
