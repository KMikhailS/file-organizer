import 'package:file_organizer/core/model/classification_rule.dart';
import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/zone_override.dart';

/// User rules: zones set by hand and classification rules.
abstract interface class RuleRepository {
  /// Zone overrides of a source, sorted by folder path.
  Future<List<ZoneOverride>> zoneOverrides(SourceId sourceId);

  /// Inserts [override] or replaces the one for the same source and folder.
  Future<void> saveZoneOverride(ZoneOverride override);

  /// Forgets the override of [folder]; does nothing if there is none. Only
  /// the rule is removed, never files.
  Future<void> removeZoneOverride(SourceId sourceId, LogicalPath folder);

  /// All classification rules, in the order they apply: by priority, then
  /// by id.
  Future<List<ClassificationRule>> classificationRules();

  /// Inserts [rule] or replaces the one with the same id.
  Future<void> saveClassificationRule(ClassificationRule rule);

  /// Forgets the rule with [id]; does nothing if there is none.
  Future<void> removeClassificationRule(String id);
}
