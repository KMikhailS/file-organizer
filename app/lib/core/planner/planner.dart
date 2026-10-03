import 'package:file_organizer/core/layout/layout_template.dart';
import 'package:file_organizer/core/layout/name_allocator.dart';
import 'package:file_organizer/core/model/classification.dart';
import 'package:file_organizer/core/model/duplicate_group.dart';
import 'package:file_organizer/core/model/file_entry.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/plan.dart';
import 'package:file_organizer/core/model/planned_operation.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/core/planner/plan_outcome.dart';
import 'package:file_organizer/core/planner/plan_validator.dart';
import 'package:file_organizer/core/ports/classifier.dart';
import 'package:file_organizer/core/ports/file_result.dart';
import 'package:file_organizer/core/ports/file_source.dart';
import 'package:file_organizer/core/zones/zone_map.dart';

/// Builds a cleanup plan for one source.
///
/// - Extra copies of duplicates **in chaos zones** are quarantined (or
///   added to the "to delete" album where the source has no quarantine).
///   Copies elsewhere are left alone and only shown. Extra copies are never
///   classified or moved.
/// - The other files of chaos zones are classified and moved into the
///   template; unresolved ones stay and are listed.
/// - Missing folders are created first, parents before children.
/// - The plan is validated (see [PlanValidator]); a violation is reported
///   as [PlanInvalid], never skipped silently.
///
/// The result is deterministic: the same input gives the same plan.
/// Planning only reads the source.
final class Planner {
  Planner({required this._classifier, required this._template});

  /// Group key of duplicate operations.
  static const String duplicatesGroup = 'duplicates';

  /// Group key of the moves into [folder] (and the folders created for it).
  static String moveGroup(LogicalPath folder) => 'move:${folder.value}';

  final Classifier _classifier;
  final LayoutTemplate _template;

  /// Plans the cleanup of [source] from its indexed [files], their [zones]
  /// and the [duplicates] found among them.
  ///
  /// Throws [ArgumentError] if any input belongs to another source.
  Future<PlanOutcome> plan({
    required FileSource source,
    required Iterable<FileEntry> files,
    required ZoneMap zones,
    Iterable<DuplicateGroup> duplicates = const [],
  }) async {
    final sourceId = source.sourceId;
    final capabilities = source.capabilities;
    if (zones.sourceId != sourceId) {
      throw ArgumentError.value(zones, 'zones', 'belongs to another source');
    }
    final indexed = files.toList()..sort((a, b) => a.path.compareTo(b.path));
    final groups = duplicates.toList()
      ..sort((a, b) => a.keeper.path.compareTo(b.keeper.path));
    if (indexed.any((f) => f.sourceId != sourceId) ||
        groups.any((g) => g.sourceId != sourceId)) {
      throw ArgumentError('files and duplicates must belong to $sourceId');
    }

    // Paths known to exist: indexed files and their folders. Folders are
    // keyed in lower case (the file system may ignore case).
    final existingPaths = <LogicalPath>{};
    final knownFolders = <String, LogicalPath>{};
    for (final file in indexed) {
      existingPaths.add(file.path);
      for (var f = file.path.parent!; !f.isRoot; f = f.parent!) {
        if (knownFolders.putIfAbsent(f.value.toLowerCase(), () => f) != f) {
          break;
        }
        existingPaths.add(f);
      }
    }

    // 1. Duplicates: only extra copies in chaos zones get an operation.
    final duplicateOps = <PlannedOperation>[];
    final extras = <LogicalPath>{};
    for (final group in groups) {
      for (final extra in group.extras) {
        extras.add(extra.path);
        if (zones.zoneOfFile(extra.path) != Zone.chaos) {
          continue;
        }
        final reason = 'duplicate of ${group.keeper.path}';
        if (capabilities.canQuarantine) {
          duplicateOps.add(
            PlannedOperation.quarantine(
              sourceId: sourceId,
              path: extra.path,
              fingerprint: extra.fingerprint,
              reason: reason,
              groupKey: duplicatesGroup,
              approved: true,
            ),
          );
        } else if (capabilities.canAddToAlbum) {
          duplicateOps.add(
            PlannedOperation.addToAlbum(
              sourceId: sourceId,
              path: extra.path,
              fingerprint: extra.fingerprint,
              reason: reason,
              groupKey: duplicatesGroup,
              approved: true,
            ),
          );
        }
      }
    }

    // 2. Other chaos files: classify and place.
    final candidates = [
      for (final file in indexed)
        if (!extras.contains(file.path) &&
            zones.zoneOfFile(file.path) == Zone.chaos)
          file,
    ];
    final unresolved = <FileEntry>[];
    final byFolder = <LogicalPath, List<(FileEntry, Classification)>>{};
    if (capabilities.canMove && candidates.isNotEmpty) {
      final results = await _classifier.classify([
        for (final file in candidates)
          ClassificationRequest(file: file, zone: Zone.chaos),
      ]);
      if (results.length != candidates.length) {
        throw StateError(
          'Classifier returned ${results.length} results for '
          '${candidates.length} files',
        );
      }
      for (var i = 0; i < candidates.length; i++) {
        final file = candidates[i];
        switch (_template.place(file, results[i])) {
          case PlaceIn(:final folder):
            (byFolder[folder] ??= []).add((file, results[i]));
          case StaysInPlace(reason: StayReason.unresolved):
            unresolved.add(file);
          case StaysInPlace(reason: StayReason.alreadyInPlace):
            break;
        }
      }
    }

    // 3. Folders, then moves, folder by folder in a stable order: each
    // missing folder is created right before the first move into it.
    final folderOps = <PlannedOperation>[];
    final createdFolders = <String, LogicalPath>{};
    final names = NameAllocator(taken: existingPaths);
    final folders = byFolder.keys.toList()..sort();
    for (final folder in folders) {
      final missing = <LogicalPath>[];
      var reachable = true;
      for (final f in _ancestorsOrSelf(folder)) {
        final key = f.value.toLowerCase();
        if (knownFolders.containsKey(key) || createdFolders.containsKey(key)) {
          continue;
        }
        switch (await source.exists(f)) {
          case FileSuccess(value: true):
            knownFolders[key] = f;
            existingPaths.add(f);
          case FileSuccess(value: false):
            missing.add(f);
          case FileFailure():
            // Unknown state: do not plan into a folder we cannot check.
            reachable = false;
        }
        if (!reachable) {
          break;
        }
      }
      if (!reachable || (missing.isNotEmpty && !capabilities.canMkdir)) {
        continue;
      }

      final group = moveGroup(folder);
      for (final f in missing) {
        folderOps.add(
          PlannedOperation.mkdir(
            sourceId: sourceId,
            path: f,
            reason: 'folder for ${folder.value}',
            groupKey: group,
            approved: true,
          ),
        );
      }
      // Later folders see these as existing.
      for (final f in missing) {
        createdFolders[f.value.toLowerCase()] = f;
      }
      for (final (file, classification) in byFolder[folder]!) {
        folderOps.add(
          PlannedOperation.move(
            sourceId: sourceId,
            from: file.path,
            to: names.claim(folder, file.name),
            fingerprint: file.fingerprint,
            reason: classification.reason,
            groupKey: group,
            approved: true,
          ),
        );
      }
    }

    final plan = Plan(
      operations: [...duplicateOps, ...folderOps],
      unresolved: unresolved,
      duplicateGroups: groups,
    );
    final violations = PlanValidator(
      sourceId: sourceId,
      capabilities: capabilities,
      zones: zones,
      existingPaths: existingPaths,
      existingFolders: knownFolders.values,
    ).validate(plan);
    return violations.isEmpty ? PlanReady(plan) : PlanInvalid(plan, violations);
  }

  /// The folders from the top level down to [folder].
  static List<LogicalPath> _ancestorsOrSelf(LogicalPath folder) {
    final chain = <LogicalPath>[];
    for (var f = folder; !f.isRoot; f = f.parent!) {
      chain.add(f);
    }
    return chain.reversed.toList();
  }
}
