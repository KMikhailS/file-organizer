import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:meta/meta.dart';

/// Where the start of the app stands.
@immutable
sealed class AppStatus {
  const AppStatus();
}

/// The database opens and the storage is being checked.
final class AppStarting extends AppStatus {
  const AppStarting();
}

/// "All files access" is not granted: nothing can be scanned.
final class AccessNeeded extends AppStatus {
  const AccessNeeded();
}

/// The storage is open and the interrupted sessions are recovered.
final class AppReady extends AppStatus {
  const AppReady(this.capabilities);

  /// What the storage allows; no capabilities means read-only.
  final SourceCapabilities capabilities;

  @override
  bool operator ==(Object other) =>
      other is AppReady && other.capabilities == capabilities;

  @override
  int get hashCode => capabilities.hashCode;
}

/// The start failed (storage not mounted, database error); [reason] is for
/// the log and the error screen.
final class StartupFailed extends AppStatus {
  const StartupFailed(this.reason);

  final String reason;

  @override
  bool operator ==(Object other) =>
      other is StartupFailed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
