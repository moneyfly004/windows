import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/utils/platform_utils.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/notifier/app_update_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class NewVersionDialog extends HookConsumerWidget with PresLogger {
  NewVersionDialog(
    this.currentVersion,
    this.newVersion, {
    this.canIgnore = true,
  }) : super(key: _dialogKey);

  final String currentVersion;
  final RemoteVersionEntity newVersion;
  final bool canIgnore;

  static final _dialogKey = GlobalKey(debugLabel: 'new version dialog');

  Future<void> show(BuildContext context) async {
    if (_dialogKey.currentContext == null) {
      return showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) => this,
      );
    } else {
      loggy.warning("new version dialog is already open");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(t.appUpdate.dialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.appUpdate.updateMsg),
          const Gap(8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${t.appUpdate.currentVersionLbl}: ",
                  style: theme.textTheme.bodySmall,
                ),
                TextSpan(
                  text: currentVersion,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: "${t.appUpdate.newVersionLbl}: ",
                  style: theme.textTheme.bodySmall,
                ),
                TextSpan(
                  text: newVersion.presentVersion,
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (canIgnore)
          TextButton(
            onPressed: () async {
              await ref.read(appUpdateNotifierProvider.notifier).ignoreRelease(newVersion);
              if (context.mounted) context.pop();
            },
            child: Text(t.appUpdate.ignoreBtnTxt),
          ),
        TextButton(
          onPressed: context.pop,
          child: Text(t.appUpdate.laterBtnTxt),
        ),
        TextButton(
          onPressed: () async {
            // 如果是 Android 且有 APK 下载链接，直接下载并安装
            if (PlatformUtils.isAndroid && newVersion.apkDownloadUrl != null) {
              try {
                final uri = Uri.parse(newVersion.apkDownloadUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // 如果无法直接打开，则打开 GitHub Release 页面
                  await UriUtils.tryLaunch(Uri.parse(newVersion.url));
                }
              } catch (e) {
                loggy.warning("Failed to launch APK download URL", e);
                // 失败时打开 GitHub Release 页面
                await UriUtils.tryLaunch(Uri.parse(newVersion.url));
              }
            } else {
              // 其他平台或没有 APK 链接时，打开 GitHub Release 页面
              await UriUtils.tryLaunch(Uri.parse(newVersion.url));
            }
          },
          child: Text(t.appUpdate.updateNowBtnTxt),
        ),
      ],
    );
  }
}
