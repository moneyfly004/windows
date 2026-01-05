import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/model/auth_models.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_update_notifier.g.dart';

@riverpod
class SubscriptionUpdateNotifier extends _$SubscriptionUpdateNotifier
    with InfraLogger {
  @override
  Future<void> build() async {
    // 初始化时自动更新订阅
    await updateSubscription();
  }

  Future<void> updateSubscription() async {
    try {
      final authRepository = await ref.read(authRepositoryProvider.future);
      
      // 检查是否已登录
      if (!authRepository.isAuthenticated()) {
        loggy.debug('用户未登录，跳过订阅更新');
        return;
      }

      // 获取订阅信息
      final subscriptionResult = await authRepository
          .getUserSubscription()
          .run();

      subscriptionResult.fold(
        (failure) {
          loggy.warning('获取订阅失败: ${failure.message}');
        },
        (subscription) async {
          if (subscription.universalUrl.isEmpty) {
            loggy.debug('订阅URL为空，跳过更新');
            return;
          }

          try {
            final profileRepository = await ref.read(profileRepositoryProvider.future);
            
            // 查找现有的订阅配置（通过URL匹配）
            final allProfiles = await profileRepository
                .watchAll()
                .first;

            allProfiles.fold(
              (failure) {
                final t = ref.read(translationsProvider);
                final failureInfo = failure.present(t);
                loggy.warning('获取配置列表失败: ${failureInfo.type} ${failureInfo.message ?? ''}');
              },
              (profiles) async {
                // 查找匹配的远程配置和旧的订阅配置
                RemoteProfileEntity? existingProfileWithSameUrl;
                List<RemoteProfileEntity> oldSubscriptionProfiles = [];
                
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
                  // 更新现有配置
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
                      final t = ref.read(translationsProvider);
                      final failureInfo = failure.present(t);
                      loggy.warning('更新订阅失败: ${failureInfo.type} ${failureInfo.message ?? ''}');
                    },
                    (_) {
                      loggy.info('订阅已更新');
                    },
                  );
                } else {
                  // 添加新配置
                  final addResult = await profileRepository
                      .addByUrl(
                        subscription.universalUrl,
                        markAsActive: true,
                      )
                      .run();

                  addResult.fold(
                    (failure) {
                      final t = ref.read(translationsProvider);
                      final failureInfo = failure.present(t);
                      loggy.warning('添加订阅失败: ${failureInfo.type} ${failureInfo.message ?? ''}');
                    },
                    (_) async {
                      // 查找刚添加的配置并更新名称
                      final allProfiles = await profileRepository
                          .watchAll()
                          .first;

                      allProfiles.fold(
                        (failure) {},
                        (profiles) async {
                          bool found = false;
                          for (final profile in profiles) {
                            if (found) break;
                            profile.maybeWhen(
                              remote: (id, active, name, url, lastUpdate, testUrl, options, subInfo) async {
                                if (url == subscription.universalUrl && !found) {
                                  found = true;
                                  await _updateProfileName(
                                    profileRepository,
                                    profile as RemoteProfileEntity,
                                    subscription,
                                  );
                                }
                              },
                              orElse: () {},
                            );
                          }
                        },
                      );
                      loggy.info('订阅已添加');
                    },
                  );
                }
              },
            );
          } catch (e) {
            loggy.error('更新订阅时出错', e);
          }
        },
      );
    } catch (e) {
      loggy.error('订阅更新异常', e);
    }
  }

  Future<void> _updateProfileName(
    ProfileRepository profileRepository,
    RemoteProfileEntity profile,
    UserSubscription subscription,
  ) async {
    try {
      // 格式化到期时间作为配置名称
      String newName = '订阅配置';
      try {
        final expireDate = DateTime.parse(subscription.expireTime);
        newName = '到期: ${DateFormat('yyyy-MM-dd HH:mm').format(expireDate)}';
      } catch (e) {
        newName = '到期: ${subscription.expireTime}';
      }

      // 更新配置名称
      final updatedProfile = profile.copyWith(name: newName);
      final patchResult = await profileRepository.patch(updatedProfile).run();

      patchResult.fold(
        (failure) {
          final t = ref.read(translationsProvider);
          final failureInfo = failure.present(t);
          loggy.warning('更新配置名称失败: ${failureInfo.type} ${failureInfo.message ?? ''}');
        },
        (_) {
          loggy.info('配置名称已更新为: $newName');
        },
      );
    } catch (e) {
      loggy.warning('更新配置名称时出错', e);
    }
  }
}

