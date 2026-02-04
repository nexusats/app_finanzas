# app_finanzas

A new Flutter project.

## Offline-first architecture (Flutter)

This app now persists accounts, categories, and transactions locally using Hive
and marks records with a `sync_status` field to track pending changes. When the
device goes online, a background sync service processes the pending queue and
updates the local cache. The UI shows a lightweight offline banner and exposes
a manual "Sincronizar" action. The last sync time is also cached locally so the
dashboard can show when the data was last refreshed.

### Local database setup

Hive is initialized on startup and stores data in three boxes:

- `accounts_box`
- `categories_box`
- `transactions_box`

Each record is stored as JSON and includes `sync_status` with one of:
`synced`, `pendingCreate`, `pendingUpdate`, `pendingDelete`.

### Backend notes (Laravel)

If you want the server to help resolve conflicts or store incremental sync
markers, consider adding:

- `sync_status` (nullable string) for optional debugging/telemetry.
- `last_synced_at` (timestamp) or an updated `updated_at` strategy.
- Optional `/sync` endpoints that accept only dirty records and return changes
  since a given timestamp.

These updates are not required for the Flutter client to work offline, but they
make conflict resolution and incremental sync more robust.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
