import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final verificationCodeController = useTextEditingController();
    final inviteCodeController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);
    final countdown = useState(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('注册'),
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
                    '创建账号',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    '请填写以下信息完成注册',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(32),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                    enabled: !isLoading.value,
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: '邮箱',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入邮箱';
                      }
                      if (!value.contains('@')) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                    enabled: !isLoading.value,
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: verificationCodeController,
                          decoration: const InputDecoration(
                            labelText: '验证码',
                            prefixIcon: Icon(Icons.verified),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !isLoading.value && countdown.value == 0,
                        ),
                      ),
                      const Gap(8),
                      SizedBox(
                        width: 120,
                        child: FilledButton(
                          onPressed: isLoading.value || countdown.value > 0
                              ? null
                              : () async {
                                  if (emailController.text.isEmpty) {
                                    showToast(
                                      context,
                                      '请先输入邮箱',
                                      type: ToastType.error,
                                    );
                                    return;
                                  }

                                  try {
                                    final repository = await ref
                                        .read(authRepositoryProvider.future);
                                    final result = await repository
                                        .sendVerificationCode(
                                          emailController.text.trim(),
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
                                      (message) {
                                        if (context.mounted) {
                                          showToast(
                                            context,
                                            message,
                                            type: ToastType.success,
                                          );
                                          // 开始倒计时
                                          countdown.value = 60;
                                          Future.doWhile(() async {
                                            await Future.delayed(
                                              const Duration(seconds: 1),
                                            );
                                            if (countdown.value > 0) {
                                              countdown.value--;
                                              return true;
                                            }
                                            return false;
                                          });
                                        }
                                      },
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      showToast(
                                        context,
                                        '发送失败: $e',
                                        type: ToastType.error,
                                      );
                                    }
                                  }
                                },
                          child: countdown.value > 0
                              ? Text('${countdown.value}秒')
                              : const Text('获取验证码'),
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
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
                  const Gap(16),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: '确认密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          obscureConfirmPassword.value =
                              !obscureConfirmPassword.value;
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: obscureConfirmPassword.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                    enabled: !isLoading.value,
                  ),
                  const Gap(16),
                  TextFormField(
                    controller: inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: '邀请码（可选）',
                      prefixIcon: Icon(Icons.card_giftcard),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isLoading.value,
                  ),
                  const Gap(24),
                  FilledButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              isLoading.value = true;
                              try {
                                final repository =
                                    await ref.read(authRepositoryProvider.future);
                                final request = RegisterRequest(
                                  username: usernameController.text.trim(),
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                  verificationCode:
                                      verificationCodeController.text.trim().isEmpty
                                          ? null
                                          : verificationCodeController.text.trim(),
                                  inviteCode:
                                      inviteCodeController.text.trim().isEmpty
                                          ? null
                                          : inviteCodeController.text.trim(),
                                );

                                final result = await repository
                                    .register(request)
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
                                  (message) {
                                    if (context.mounted) {
                                      showToast(
                                        context,
                                        message,
                                        type: ToastType.success,
                                      );
                                      // 返回登录页面
                                      Navigator.of(context).pop();
                                    }
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
                        : const Text('注册'),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('已有账号？'),
                      TextButton(
                        onPressed: isLoading.value
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: const Text('立即登录'),
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

