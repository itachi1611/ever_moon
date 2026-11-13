import 'package:ever_moon/utils/device_form_factor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasLeanback', () {
    test('a TV lists the leanback feature', () {
      expect(
        hasLeanback(['android.hardware.wifi', 'android.software.leanback']),
        isTrue,
      );
    });

    test('a phone does not', () {
      expect(
        hasLeanback(['android.hardware.touchscreen', 'android.hardware.wifi']),
        isFalse,
      );
      expect(hasLeanback(const []), isFalse);
    });
  });

  test('off Android the app is never treated as a TV', () async {
    // The test host is macOS or Linux, not Android.
    expect(await isAndroidTv(), isFalse);
  });
}
