import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class LoadingRegistry {
  LoadingRegistry._();

  static final ValueNotifier<int> counter = ValueNotifier<int>(0);

  static int _pendingDelta = 0;
  static bool _flushScheduled = false;

  static void start() {
    _pendingDelta += 1;
    _scheduleFlush();
  }

  static void stop() {
    _pendingDelta -= 1;
    _scheduleFlush();
  }

  static Future<T> run<T>(Future<T> Function() action) async {
    start();
    try {
      return await action();
    } finally {
      stop();
    }
  }

  static void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;

    void flush() {
      _flushScheduled = false;

      if (_pendingDelta == 0) return;

      final next = counter.value + _pendingDelta;
      _pendingDelta = 0;
      counter.value = next < 0 ? 0 : next;
    }

    final phase = SchedulerBinding.instance.schedulerPhase;

    // Si NO estamos en build/layout/paint, aplicamos ya.
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      flush();
      return;
    }

    // Si estamos en build, lo diferimos al siguiente frame.
    SchedulerBinding.instance.addPostFrameCallback((_) => flush());
  }
}
