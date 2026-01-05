import 'package:flutter/material.dart';
import 'package:hiddify/utils/alerts.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

void showToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
}) {
  switch (type) {
    case ToastType.success:
      CustomToast.success(message).show(context);
      break;
    case ToastType.error:
      CustomToast.error(message).show(context);
      break;
    case ToastType.warning:
      CustomToast(message, type: AlertType.info).show(context);
      break;
    case ToastType.info:
      CustomToast(message, type: AlertType.info).show(context);
      break;
  }
}

