import 'package:dartx/dartx.dart';
import 'package:hiddify/core/model/environment.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';

abstract class GithubReleaseParser {
  static RemoteVersionEntity parse(Map<String, dynamic> json) {
    final fullTag = json['tag_name'] as String;
    final fullVersion = fullTag.removePrefix("v").split("-").first.split("+");
    var version = fullVersion.first;
    var buildNumber = fullVersion.elementAtOrElse(1, (index) => "");
    var flavor = Environment.prod;
    for (final env in Environment.values) {
      final suffix = ".${env.name}";
      if (version.endsWith(suffix)) {
        version = version.removeSuffix(suffix);
        flavor = env;
        break;
      } else if (buildNumber.endsWith(suffix)) {
        buildNumber = buildNumber.removeSuffix(suffix);
        flavor = env;
        break;
      }
    }
    final preRelease = json["prerelease"] as bool;
    final publishedAt = DateTime.parse(json["published_at"] as String);
    
    // 查找 APK 下载链接（Android）
    String? apkDownloadUrl;
    if (json["assets"] != null) {
      final assets = json["assets"] as List;
      // 优先查找 release APK
      final apkAsset = assets.firstWhere(
        (asset) {
          final name = (asset as Map<String, dynamic>)["name"] as String;
          return name.endsWith(".apk") && 
                 (name.contains("release") || name.contains("moneyfly"));
        },
        orElse: () => null,
      );
      if (apkAsset != null) {
        apkDownloadUrl = (apkAsset as Map<String, dynamic>)["browser_download_url"] as String;
      } else {
        // 如果没有找到 release APK，查找任何 APK
        final anyApkAsset = assets.firstWhere(
          (asset) {
            final name = (asset as Map<String, dynamic>)["name"] as String;
            return name.endsWith(".apk");
          },
          orElse: () => null,
        );
        if (anyApkAsset != null) {
          apkDownloadUrl = (anyApkAsset as Map<String, dynamic>)["browser_download_url"] as String;
        }
      }
    }
    
    return RemoteVersionEntity(
      version: version,
      buildNumber: buildNumber,
      releaseTag: fullTag,
      preRelease: preRelease,
      url: json["html_url"] as String,
      publishedAt: publishedAt,
      flavor: flavor,
      apkDownloadUrl: apkDownloadUrl,
    );
  }
}
