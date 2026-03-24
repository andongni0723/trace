import 'dart:math';

import 'package:package_info_plus/package_info_plus.dart';

Future<String> getAppVersion() async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
}

Future<String> getAppName() async {
  final info = await PackageInfo.fromPlatform();
  return info.appName;
}

int compareVersion(String left, String right) {
  final leftParts = left.split('.');
  final rightParts = right.split('.');
  final maxLength = max(leftParts.length, rightParts.length);

  for (var index = 0; index < maxLength; index++) {
    final leftValue = leftParts.length > index ? int.parse(leftParts[index]) : 0;
    final rightValue = rightParts.length > index
        ? int.parse(rightParts[index])
        : 0;

    if (leftValue != rightValue) {
      return leftValue.compareTo(rightValue);
    }
  }

  return 0;
}

double bytesToMiB(int bytes) => bytes / (1024 * 1024);

double progressOf(double value, double max) {
  if (max == 0) return 0;
  return (value / max).clamp(0.0, 1.0);
}
