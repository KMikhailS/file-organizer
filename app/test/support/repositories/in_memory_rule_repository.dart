import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';

class InMemoryRuleRepository implements RuleRepository {
  final Map<SourceId, Map<LogicalPath, ZoneOverride>> _zones = {};
  final Map<String, ClassificationRule> _rules = {};

  @override
  Future<List<ZoneOverride>> zoneOverrides(SourceId sourceId) async =>
      (_zones[sourceId]?.values.toList() ?? [])
        ..sort((a, b) => a.folder.compareTo(b.folder));

  @override
  Future<void> saveZoneOverride(ZoneOverride override) async =>
      (_zones[override.sourceId] ??= {})[override.folder] = override;

  @override
  Future<void> removeZoneOverride(
    SourceId sourceId,
    LogicalPath folder,
  ) async => _zones[sourceId]?.remove(folder);

  @override
  Future<List<ClassificationRule>> classificationRules() async =>
      _rules.values.toList()..sort((a, b) {
        final byPriority = a.priority.compareTo(b.priority);
        return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
      });

  @override
  Future<void> saveClassificationRule(ClassificationRule rule) async =>
      _rules[rule.id] = rule;

  @override
  Future<void> removeClassificationRule(String id) async => _rules.remove(id);
}
