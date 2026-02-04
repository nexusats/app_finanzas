import 'dart:async';

import 'package:app_finanzas/app/services/local/local_database.dart';
import 'package:app_finanzas/app/services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity;
  final SyncService _syncService;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  DateTime? _lastSyncAt;

  bool get isOnline => _isOnline;
  DateTime? get lastSyncAt => _lastSyncAt;

  ConnectivityProvider({
    Connectivity? connectivity,
    SyncService? syncService,
  })  : _connectivity = connectivity ?? Connectivity(),
        _syncService = syncService ?? SyncService() {
    _lastSyncAt = LocalDatabase.getLastSyncAt();
    _subscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivity);
    _refreshInitialStatus();
  }

  Future<void> _refreshInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _handleConnectivity(result);
  }

  void _handleConnectivity(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (_isOnline != isConnected) {
      _isOnline = isConnected;
      notifyListeners();
      if (_isOnline) {
        _triggerSync();
      }
    }
  }

  Future<void> manualSync() async {
    if (!_isOnline) return;
    await _triggerSync();
  }

  Future<void> _triggerSync() async {
    await _syncService.syncAll();
    _lastSyncAt = LocalDatabase.getLastSyncAt();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
