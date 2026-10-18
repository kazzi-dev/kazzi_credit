import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Blocks screenshots and screen recording (Android FLAG_SECURE) while
/// sensitive data is on screen. iOS has no equivalent API; the app-switcher
/// blur covers the main risk there.
class SecureScreen {
  static const _channel = MethodChannel('kazzi/secure_screen');

  Future<void> set({required bool enabled}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // Not wired up on this platform build; fail open rather than crash.
    } on PlatformException {
      // Same.
    }
  }
}

final secureScreenProvider = Provider<SecureScreen>((ref) => SecureScreen());
