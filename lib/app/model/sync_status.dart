enum SyncStatus {
  synced,
  pendingCreate,
  pendingUpdate,
  pendingDelete,
}

SyncStatus syncStatusFromString(String? value) {
  switch (value) {
    case 'pendingCreate':
      return SyncStatus.pendingCreate;
    case 'pendingUpdate':
      return SyncStatus.pendingUpdate;
    case 'pendingDelete':
      return SyncStatus.pendingDelete;
    case 'synced':
    default:
      return SyncStatus.synced;
  }
}

String syncStatusToString(SyncStatus status) {
  switch (status) {
    case SyncStatus.pendingCreate:
      return 'pendingCreate';
    case SyncStatus.pendingUpdate:
      return 'pendingUpdate';
    case SyncStatus.pendingDelete:
      return 'pendingDelete';
    case SyncStatus.synced:
      return 'synced';
  }
}
