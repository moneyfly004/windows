import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/package/data/package_data_providers.dart';
import 'package:hiddify/features/package/model/package_models.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends HookConsumerWidget {
  const PaymentPage({
    super.key,
    this.order,
    this.package,
  });

  final Order? order;
  final Package? package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final currentOrder = useState<Order?>(order);
    final paymentUrl = useState<String?>(null);
    final qrCode = useState<String?>(null);
    Timer? pollTimer;

    // 如果没有订单，先创建订单
    useEffect(() {
      if (order == null && package != null) {
        Future.microtask(() async {
          isLoading.value = true;
          try {
            final repository = await ref.read(packageRepositoryProvider.future);
            final request = CreateOrderRequest(
              packageId: package!.id,
              paymentMethod: 'alipay',
            );

            final result = await repository.createOrder(request).run();

            result.fold(
              (failure) {
                if (context.mounted) {
                  showToast(
                    context,
                    failure.message,
                    type: ToastType.error,
                  );
                  Navigator.of(context).pop();
                }
              },
              (newOrder) {
                currentOrder.value = newOrder;
                paymentUrl.value = newOrder.paymentUrl;
                qrCode.value = newOrder.paymentQrCode ?? newOrder.paymentUrl;
                
                // 开始轮询订单状态
                pollTimer = Timer.periodic(
                  const Duration(seconds: 3),
                  (timer) async {
                    if (currentOrder.value == null) {
                      timer.cancel();
                      return;
                    }

                    final statusResult = await repository
                        .getOrderStatus(currentOrder.value!.orderNo)
                        .run();

                    statusResult.fold(
                      (failure) {
                        // 查询失败，继续轮询
                      },
                      (updatedOrder) {
                        if (updatedOrder.status == 'paid') {
                          timer.cancel();
                          if (context.mounted) {
                            showToast(
                              context,
                              '支付成功！',
                              type: ToastType.success,
                            );
                            // 返回主页并刷新订阅
                            const HomeRoute().go(context);
                          }
                        } else if (updatedOrder.status == 'cancelled' ||
                            updatedOrder.status == 'expired') {
                          timer.cancel();
                          if (context.mounted) {
                            showToast(
                              context,
                              '订单已取消或过期',
                              type: ToastType.error,
                            );
                            Navigator.of(context).pop();
                          }
                        }
                        currentOrder.value = updatedOrder;
                      },
                    );
                  },
                );
              },
            );
          } finally {
            if (context.mounted) {
              isLoading.value = false;
            }
          }
        });
      } else {
        paymentUrl.value = order!.paymentUrl;
        qrCode.value = order!.paymentQrCode ?? order!.paymentUrl;
      }

      return () {
        pollTimer?.cancel();
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支付订单'),
      ),
      body: SafeArea(
        child: isLoading.value
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : currentOrder.value == null || package == null
                ? const Center(
                    child: Text('订单创建失败或套餐信息缺失'),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Gap(16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  '订单信息',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Gap(16),
                                _InfoRow(
                                  label: '订单号',
                                  value: currentOrder.value!.orderNo,
                                ),
                                const Divider(),
                                _InfoRow(
                                  label: '套餐名称',
                                  value: package!.name,
                                ),
                                const Divider(),
                                _InfoRow(
                                  label: '支付金额',
                                  value: '¥${(currentOrder.value!.finalAmount ?? currentOrder.value!.amount).toStringAsFixed(2)}',
                                  valueStyle: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                if (currentOrder.value!.discountAmount != null &&
                                    currentOrder.value!.discountAmount! > 0) ...[
                                  const Divider(),
                                  _InfoRow(
                                    label: '优惠金额',
                                    value: '¥${currentOrder.value!.discountAmount!.toStringAsFixed(2)}',
                                    valueStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Gap(24),
                        if (qrCode.value != null) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    '扫码支付',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const Gap(16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: QrImageView(
                                      data: qrCode.value!,
                                      size: 200,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const Gap(16),
                                  Text(
                                    '请使用支付宝扫描上方二维码完成支付',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(16),
                        ],
                        if (paymentUrl.value != null) ...[
                          FilledButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(paymentUrl.value!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                if (context.mounted) {
                                  showToast(
                                    context,
                                    '无法打开支付链接',
                                    type: ToastType.error,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('跳转到支付宝支付'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const Gap(8),
                        ],
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('取消订单'),
                        ),
                        const Gap(16),
                        Text(
                          '支付成功后，系统将自动开通套餐',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: valueStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

