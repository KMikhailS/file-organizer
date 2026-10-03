import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/plan.dart';
import 'package:file_organizer/core/model/source_capabilities.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/core/planner/plan_violation.dart';
import 'package:file_organizer/core/zones/zone_map.dart';

/// Checks a plan against the safety rules:
///
/// - nothing is overwritten: targets are free and claimed once (compared
///   case-insensitively);
/// - every operation stays in the source;
/// - files are only taken from chaos zones, and only put into target
///   folders (excluded, organized and target files are never touched);
///   folders are only created in target folders or on the way to them;
/// - the source supports every operation;
/// - no file takes part in two operations;
/// - every parent folder exists or is created earlier in the plan.
final class PlanValidator {
  /// [existingPaths] are the files and folders known to exist;
  /// [existingFolders] the folders among them.
  PlanValidator({
    required this.sourceId,
    required this.capabilities,
    required this.zones,
    required Iterable<LogicalPath> existingPaths,
    required Iterable<LogicalPath> existingFolders,
  }) : _existing = {for (final p in existingPaths) _key(p)},
       _folders = {for (final p in existingFolders) _key(p)};

  final SourceId sourceId;
  final SourceCapabilities capabilities;
  final ZoneMap zones;
  final Set<String> _existing;
  final Set<String> _folders;

  /// All violations, in plan order; empty for a valid plan.
  List<PlanViolation> validate(Plan plan) {
    final violations = <PlanViolation>[];
    final targets = <String>{};
    final sources = <String>{};
    final created = <String>{};

    for (final op in plan.operations) {
      void violation(ViolationKind kind, String message) =>
          violations.add(PlanViolation(kind, op, message));

      if (op.sourceId != sourceId) {
        violation(ViolationKind.leavesSource, 'belongs to ${op.sourceId}');
      }
      if (!_supported(op.type)) {
        violation(ViolationKind.unsupported, '${op.type.name} unsupported');
      }

      if (op.fromPath case final from?) {
        final zone = zones.zoneOfFile(from);
        if (zone != Zone.chaos) {
          violation(
            ViolationKind.protectedZone,
            '$from is in a ${zone.name} zone',
          );
        }
        // Exact path: it names one indexed file. Case variants are
        // different files on case-sensitive systems, and cannot both exist
        // on the others.
        if (!sources.add(from.value)) {
          violation(ViolationKind.fileUsedTwice, '$from is used twice');
        }
      }

      if (op.toPath case final to?) {
        final key = _key(to);
        if (_existing.contains(key) || _folders.contains(key)) {
          violation(ViolationKind.overwrite, '$to already exists');
        }
        if (!targets.add(key)) {
          violation(ViolationKind.duplicateTarget, '$to is targeted twice');
        }
        final folder = op.type == OperationType.mkdir ? to : to.parent!;
        final zone = zones.zoneOfFolder(folder);
        final onTheWay =
            op.type == OperationType.mkdir && _leadsToTarget(folder);
        if (zone != Zone.target && !onTheWay) {
          violation(
            ViolationKind.protectedZone,
            '$folder is a ${zone.name} folder, not a target one',
          );
        }
        final parent = to.parent!;
        final parentKey = _key(parent);
        if (!parent.isRoot &&
            !_folders.contains(parentKey) &&
            !created.contains(parentKey)) {
          violation(ViolationKind.missingParent, 'no folder $parent');
        }
        if (op.type == OperationType.mkdir) {
          created.add(key);
        }
      }
    }
    return violations;
  }

  /// Whether [folder] lies on the way to a template folder (such as a
  /// custom template root): creating it touches no existing file.
  bool _leadsToTarget(LogicalPath folder) {
    final prefix = '${_key(folder)}/';
    return zones.config.targetFolders.any((t) => _key(t).startsWith(prefix));
  }

  bool _supported(OperationType type) => switch (type) {
    OperationType.mkdir => capabilities.canMkdir,
    OperationType.move => capabilities.canMove,
    OperationType.quarantine => capabilities.canQuarantine,
    OperationType.addToAlbum => capabilities.canAddToAlbum,
  };

  static String _key(LogicalPath path) => path.value.toLowerCase();
}
