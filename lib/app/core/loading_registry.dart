import 'package:flutter/foundation.dart';

class LoadingRegistry {
  LoadingRegistry._();

  static final ValueNotifier<int> counter = ValueNotifier<int>(0);

  static void start() {
    counter.value = counter.value + 1;
  }

  static void stop() {
    if (counter.value > 0) counter.value = counter.value - 1;
  }

  static Future<T> run<T>(Future<T> Function() action) async {
    start();
    try {
      return await action();
    } finally {
      stop();
    }
  }
}
