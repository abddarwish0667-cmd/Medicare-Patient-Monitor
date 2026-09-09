import 'package:flutter/foundation.dart';

class AppMode {
  AppMode._();

  static final ValueNotifier<bool> demoMode =
      ValueNotifier<bool>(false);

  static bool get isDemo => demoMode.value;

  static bool get isRealDevice => !demoMode.value;

  static void enableDemo() {
    demoMode.value = true;
  }

  static void enableRealDevice() {
    demoMode.value = false;
  }

  static void reset() {
    demoMode.value = false;
  }
}