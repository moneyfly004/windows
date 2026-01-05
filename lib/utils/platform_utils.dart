import 'dart:io';

abstract class PlatformUtils {
  static bool get isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  static bool get isAndroid => Platform.isAndroid;

  static bool get isIOS => Platform.isIOS;
}
