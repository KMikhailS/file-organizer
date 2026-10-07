import 'dart:convert';

import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/quarantine_ref.dart';
import 'package:meta/meta.dart';

/// Where the adapter keeps its own files inside the source
/// (`docs/stage2_android.md`, decision A.4):
///
/// ```
/// .FileOrganizer/
///   .nomedia                      gallery apps skip the folder
///   probe/                        capability probe files (empty)
///   placeholders/                 placeholders of failed moves (empty)
///   quarantine/<sessionId>/<n>    a quarantined file
///   quarantine/<sessionId>/<n>.json   its description
/// ```
///
/// A [QuarantineRef] is `<sessionId>/<n>`; anything else is not a
/// reference of this adapter.
abstract final class AppFolder {
  /// Name of the folder in the source root.
  static const String name = '.FileOrganizer';

  static final LogicalPath root = LogicalPath(name);
  static final LogicalPath noMedia = root.child('.nomedia');
  static final LogicalPath probe = root.child('probe');
  static final LogicalPath placeholders = root.child('placeholders');
  static final LogicalPath quarantine = root.child('quarantine');

  /// Whether [path] is the app folder or lies inside it. Compared without
  /// case: shared storage on Android ignores it.
  static bool contains(LogicalPath path) =>
      !path.isRoot && path.segments.first.toLowerCase() == name.toLowerCase();

  /// The folder of [sessionId] in the quarantine, or `null` if the id cannot
  /// be a folder name.
  static LogicalPath? sessionFolder(SessionId sessionId) =>
      _segment.hasMatch(sessionId.value)
      ? quarantine.child(sessionId.value)
      : null;

  /// The quarantined file of [ref] and its description, or `null` if [ref]
  /// is not a reference of this adapter.
  static ({LogicalPath file, LogicalPath description})? locate(
    QuarantineRef ref,
  ) {
    final match = _ref.firstMatch(ref.value);
    if (match == null) {
      return null;
    }
    final folder = quarantine.child(match.group(1)!);
    final n = match.group(2)!;
    return (file: folder.child(n), description: folder.child('$n.json'));
  }

  /// The reference of the file number [n] of [sessionId].
  static QuarantineRef ref(SessionId sessionId, int n) =>
      QuarantineRef('${sessionId.value}/$n');

  /// The number of a quarantine entry name (`<n>` or `<n>.json`), or `null`.
  static int? numberOf(String entryName) {
    final match = _entry.firstMatch(entryName);
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// A session id that can be a folder name: letters, digits, `.`, `_`,
  /// `-`, not starting with a dot.
  static final RegExp _segment = RegExp(
    r'^[A-Za-z0-9_-][A-Za-z0-9._-]{0,127}$',
  );

  static final RegExp _ref = RegExp(
    r'^([A-Za-z0-9_-][A-Za-z0-9._-]{0,127})/([1-9][0-9]{0,9})$',
  );

  static final RegExp _entry = RegExp(r'^([1-9][0-9]{0,9})(?:\.json)?$');
}

/// The description kept next to a quarantined file.
@immutable
final class QuarantineDescription {
  QuarantineDescription({
    required this.original,
    required this.size,
    required DateTime modifiedAt,
    required DateTime quarantinedAt,
  }) : modifiedAt = modifiedAt.toUtc(),
       quarantinedAt = quarantinedAt.toUtc();

  /// Where the file was.
  final LogicalPath original;
  final int size;
  final DateTime modifiedAt;
  final DateTime quarantinedAt;

  String encode() => jsonEncode({
    'original': original.value,
    'size': size,
    'modifiedAt': modifiedAt.toIso8601String(),
    'quarantinedAt': quarantinedAt.toIso8601String(),
  });

  /// Reads what [encode] wrote; `null` for anything else (an empty file left
  /// by a crash, a damaged file).
  static QuarantineDescription? decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      return null;
    }
    if (json
        case {
          'original': final String original,
          'size': final int size,
          'modifiedAt': final String modifiedAt,
          'quarantinedAt': final String quarantinedAt,
        }
        when LogicalPath.problemWith(original) == null && original.isNotEmpty) {
      final modified = DateTime.tryParse(modifiedAt);
      final quarantined = DateTime.tryParse(quarantinedAt);
      if (modified != null && quarantined != null && size >= 0) {
        return QuarantineDescription(
          original: LogicalPath(original),
          size: size,
          modifiedAt: modified,
          quarantinedAt: quarantined,
        );
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is QuarantineDescription &&
      other.original == original &&
      other.size == size &&
      other.modifiedAt == modifiedAt &&
      other.quarantinedAt == quarantinedAt;

  @override
  int get hashCode => Object.hash(original, size, modifiedAt, quarantinedAt);

  @override
  String toString() => 'QuarantineDescription($original, $size bytes)';
}
