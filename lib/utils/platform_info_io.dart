import 'dart:io';

class PlatformInfo {
  const PlatformInfo();

  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;
  bool get isMacOS => Platform.isMacOS;
  bool get isWindows => Platform.isWindows;
  bool get isLinux => Platform.isLinux;
}

const platformInfo = PlatformInfo();

