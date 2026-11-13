import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ever_moon/utils/app_logger.dart' as logger;

/// Android system feature that every Android TV and Google TV device has.
const String leanbackFeature = 'android.software.leanback';

/// Whether [systemFeatures] describe an Android TV device.
bool hasLeanback(Iterable<String> systemFeatures) =>
    systemFeatures.contains(leanbackFeature);

/// Whether the app runs on Android TV or Google TV.
///
/// `false` off Android, and `false` when the feature list cannot be read
/// (logged), so a failure keeps the phone behaviour.
Future<bool> isAndroidTv() async {
  if (!Platform.isAndroid) return false;
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    return hasLeanback(info.systemFeatures);
  } catch (error, stackTrace) {
    logger.err('Could not read the device features', error, stackTrace);
    return false;
  }
}
