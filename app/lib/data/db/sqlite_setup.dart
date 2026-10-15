import 'package:sqlite3/common.dart';

/// Settings of the app's database connection
/// (`docs/stage2_android.md`, 5.27).
///
/// Write-ahead log with `synchronous = FULL`: every committed transaction
/// is on the disk before the call returns, so an operation journaled as
/// pending stays pending even if the power goes out right after (safety
/// invariant 3); WAL only needs one sync per commit instead of several.
/// `synchronous = NORMAL` would be faster and is deliberately not used: it
/// can lose the last commits on a power loss.
///
/// A top-level function: the database may be opened in another isolate.
void configureSqlite(CommonDatabase db) {
  db
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA synchronous = FULL');
}
