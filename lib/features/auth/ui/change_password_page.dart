import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChangePasswordPage extends HookConsumerWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final verificationCodeController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final step = useState(0); // 0: 发送验证码, 1: 修改密码
    final countdown = useState(0);
    final obscureNewPassword = useState(true);
    final obscureConfirmPassword = useState(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改密码'),
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
                    '修改密码',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    '请填写以下信息修改密码',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(32),
                  if (step.value == 0) ...[
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
                                            step.value = 1;
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
                  ] else ...[
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入验证码';
                              }
                              return null;
                            },
                            enabled: !isLoading.value,
                          ),
                        ),
                        const Gap(8),
                        SizedBox(
                          width: 120,
                          child: OutlinedButton(
                            onPressed: countdown.value > 0
                                ? null
                                : () {
                                    step.value = 0;
                                    verificationCodeController.clear();
                                  },
                            child: countdown.value > 0
                                ? Text('${countdown.value}秒')
                                : const Text('重新发送'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Gap(16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          obscureNewPassword.value = !obscureNewPassword.value;
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: obscureNewPassword.value,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入新密码';
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
                      labelText: '确认新密码',
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
                        return '请确认新密码';
                      }
                      if (value != newPasswordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                    enabled: !isLoading.value,
                  ),
                  const Gap(24),
                  FilledButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              isLoading.value = true;
                              if (step.value == 0) {
                                // 第一步：发送验证码
                                if (formKey.currentState!.validate()) {
                                  // 验证码发送逻辑在上面已经处理
                                }
                                return;
                              }

                              // 第二步：修改密码
                              try {
                                final repository = await ref
                                    .read(authRepositoryProvider.future);
                                
                                // 使用验证码重置密码
                                final result = await repository
                                    .resetPassword(
                                      emailController.text.trim(),
                                      verificationCodeController.text.trim(),
                                      newPasswordController.text,
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
                        : const Text('修改密码'),
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

