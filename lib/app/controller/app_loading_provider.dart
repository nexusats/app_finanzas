import 'package:flutter/material.dart';

class AppLoadingProvider extends ChangeNotifier {
  int _count = 0;

  bool get isLoading => _count > 0;

  void start() {
    _count++;
    notifyListeners();
  }

  void stop() {
    if (_count > 0) _count--;
    notifyListeners();
  }

  Future<T> run<T>(Future<T> Function() action) async {
    start();
    try {
      return await action();
    } finally {
      stop();
    }
  }
}
