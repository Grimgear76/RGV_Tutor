class PlatformInfo {
  const PlatformInfo();

  bool get isAndroid => false;
  bool get isIOS => false;
  bool get isMacOS => false;
  bool get isWindows => false;
  bool get isLinux => false;
}

const platformInfo = PlatformInfo();

