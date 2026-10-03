import 'package:file_organizer/core/dedupe/copy_marker.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/zone.dart';

/// Chooses which of identical [files] to keep.
///
/// Rules, in order, until one tells the files apart:
/// 1. lies in an organized or target folder rather than a chaos zone;
/// 2. earlier modification time;
/// 3. name without a copy marker (see [hasCopyMarker]);
/// 4. shorter path;
/// 5. alphabetically first path.
///
/// The reason is the rule that set the keeper apart from the runner-up.
/// The result does not depend on the order of [files]. [zoneOf] gives the
/// zone of each file; excluded files must not be passed.
({FileEntry keeper, KeeperReason reason}) chooseKeeper(
  List<FileEntry> files,
  Zone Function(FileEntry file) zoneOf,
) {
  if (files.length < 2) {
    throw ArgumentError.value(files, 'files', 'needs at least two files');
  }
  final ranked = [for (final file in files) _Ranked(file, zoneOf(file))]
    ..sort(_compare);
  return (
    keeper: ranked[0].file,
    reason: _firstDifference(ranked[0], ranked[1]),
  );
}

final class _Ranked {
  _Ranked(this.file, Zone zone)
    : location = switch (zone) {
        Zone.organized || Zone.target => 0,
        Zone.chaos => 1,
        Zone.excluded => throw ArgumentError.value(
          file,
          'files',
          'excluded files take no part in duplicate detection',
        ),
      },
      copy = hasCopyMarker(file.name) ? 1 : 0;

  final FileEntry file;
  final int location;
  final int copy;
}

/// The keeper rules as comparisons, in order.
final List<(KeeperReason, int Function(_Ranked, _Ranked))> _rules = [
  (KeeperReason.organizedLocation, (a, b) => a.location.compareTo(b.location)),
  (
    KeeperReason.earliestModified,
    (a, b) => a.file.modifiedAt.compareTo(b.file.modifiedAt),
  ),
  (KeeperReason.notACopy, (a, b) => a.copy.compareTo(b.copy)),
  (
    KeeperReason.shortestPath,
    (a, b) => a.file.path.value.length.compareTo(b.file.path.value.length),
  ),
  (KeeperReason.alphabeticalPath, (a, b) => a.file.path.compareTo(b.file.path)),
];

int _compare(_Ranked a, _Ranked b) {
  for (final (_, compare) in _rules) {
    final result = compare(a, b);
    if (result != 0) {
      return result;
    }
  }
  return 0;
}

KeeperReason _firstDifference(_Ranked keeper, _Ranked runnerUp) {
  for (final (reason, compare) in _rules) {
    if (compare(keeper, runnerUp) != 0) {
      return reason;
    }
  }
  // Paths in a group are distinct, so the last rule always decides.
  throw StateError('identical paths in a duplicate group');
}
