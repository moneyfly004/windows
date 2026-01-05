import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ForgotPasswordPage extends HookConsumerWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final codeController = useTextEditingController();
    final newPasswordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isLoading = useState(false);
    final step = useState(0); // 0: 发送验证码, 1: 重置密码
    final countdown = useState(0);
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('忘记密码'),
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
                    step.value == 0 ? '找回密码' : '重置密码',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const Gap(8),
                  Text(
                    step.value == 0
                        ? '请输入您的邮箱，我们将发送验证码'
                        : '请输入验证码和新密码',
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
                    const Gap(24),
                    FilledButton(
                      onPressed: isLoading.value || countdown.value > 0
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                isLoading.value = true;
                                try {
                                  final repository = await ref
                                      .read(authRepositoryProvider.future);
                                  final result = await repository
                                      .forgotPassword(emailController.text.trim())
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
                          : const Text('发送验证码'),
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
                            controller: codeController,
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
                                    codeController.clear();
                                  },
                            child: countdown.value > 0
                                ? Text('${countdown.value}秒')
                                : const Text('重新发送'),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: newPasswordController,
                      decoration: InputDecoration(
                        labelText: '新密码',
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
                                try {
                                  final repository = await ref
                                      .read(authRepositoryProvider.future);
                                  final result = await repository
                                      .resetPassword(
                                        emailController.text.trim(),
                                        codeController.text.trim(),
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
                          : const Text('重置密码'),
                    ),
                  ],
                  const Gap(16),
                  TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('返回登录'),
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

