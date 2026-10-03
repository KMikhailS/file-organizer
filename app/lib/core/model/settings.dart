import 'package:meta/meta.dart';

/// App settings that the core uses.
@immutable
final class Settings {
  /// Throws [ArgumentError] if [quarantineRetention] is shorter than
  /// [minQuarantineRetention].
  Settings({this.quarantineRetention = defaultQuarantineRetention}) {
    if (quarantineRetention < minQuarantineRetention) {
      throw ArgumentError.value(
        quarantineRetention,
        'quarantineRetention',
        'must be at least $minQuarantineRetention',
      );
    }
  }

  static const Duration defaultQuarantineRetention = Duration(days: 30);

  /// A misconfigured setting must not purge the quarantine right after a
  /// cleanup.
  static const Duration minQuarantineRetention = Duration(days: 1);

  /// How long quarantined files are kept before they are purged.
  final Duration quarantineRetention;

  @override
  bool operator ==(Object other) =>
      other is Settings && other.quarantineRetention == quarantineRetention;

  @override
  int get hashCode => quarantineRetention.hashCode;

  @override
  String toString() => 'Settings(quarantineRetention: $quarantineRetention)';
}
