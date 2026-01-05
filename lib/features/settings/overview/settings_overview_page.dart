import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/settings/about/about_page.dart';
import 'package:hiddify/features/settings/widgets/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsOverviewPage extends HookConsumerWidget {
  const SettingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

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
              // 关于
              ListTile(
                leading: const Icon(FluentIcons.info_24_regular),
                title: Text(t.about.pageTitle),
                trailing: const Icon(FluentIcons.chevron_right_24_regular),
                onTap: () {
                  const AboutRoute().push(context);
                },
              ),
              const Gap(16),
            ],
          ),
        ],
      ),
    );
  }
}
