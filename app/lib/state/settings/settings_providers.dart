import 'package:file_organizer/core/model/classification_rule.dart';
import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/core/model/settings.dart';
import 'package:file_organizer/core/model/zone.dart';
import 'package:file_organizer/core/model/zone_override.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The settings screen (`docs/stage2_android.md`, section 9, screen 8 and
// 5.23). Every change is saved at once; the next plan follows the zone
// marks and rules, the next start the quarantine retention.

/// The quarantine retentions the user can choose (decision of task 15).
const List<Duration> quarantineRetentions = [
  Duration(days: 7),
  Duration(days: 14),
  Duration(days: 30),
  Duration(days: 60),
  Duration(days: 90),
];

/// The languages of the UI the user can choose; `null` follows the system.
const List<String?> uiLanguages = [null, 'ru', 'en'];

/// The stored settings.
final class SettingsNotifier extends AsyncNotifier<Settings> {
  @override
  Future<Settings> build() => ref.read(repositoriesProvider).settings.load();

  /// Copies of the quarantine older than [retention] are purged on the
  /// next start of the app.
  Future<void> setQuarantineRetention(Duration retention) =>
      _save((s) => s.copyWith(quarantineRetention: retention));

  /// The language of the UI (`null`: the system's). The screens and the
  /// notification follow at once.
  Future<void> setUiLocale(String? locale) async {
    await _save((s) => s.copyWith(uiLocale: () => locale));
    ref.read(uiLocaleProvider.notifier).set(locale);
  }

  Future<void> _save(Settings Function(Settings) change) async {
    final repository = ref.read(repositoriesProvider).settings;
    final changed = change(await repository.load());
    await repository.save(changed);
    state = AsyncData(changed);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

/// The zone marks of the shared storage, sorted by folder.
final class ZoneMarks extends AsyncNotifier<List<ZoneOverride>> {
  @override
  Future<List<ZoneOverride>> build() => ref
      .read(repositoriesProvider)
      .rules
      .zoneOverrides(AppController.storageId);

  /// Marks [folder] (replacing its mark). [zone] is [Zone.chaos],
  /// [Zone.organized] or [Zone.excluded].
  Future<void> mark(LogicalPath folder, Zone zone) async {
    await ref
        .read(repositoriesProvider)
        .rules
        .saveZoneOverride(
          ZoneOverride(
            sourceId: AppController.storageId,
            folder: folder,
            zone: zone,
          ),
        );
    await _reload();
  }

  /// Forgets the mark of [folder]; only the mark, never files.
  Future<void> unmark(LogicalPath folder) async {
    await ref
        .read(repositoriesProvider)
        .rules
        .removeZoneOverride(AppController.storageId, folder);
    await _reload();
  }

  Future<void> _reload() async => state = AsyncData(await build());
}

final zoneMarksProvider = AsyncNotifierProvider<ZoneMarks, List<ZoneOverride>>(
  ZoneMarks.new,
);

/// The user's classification rules, in the order they apply.
final class UserRules extends AsyncNotifier<List<ClassificationRule>> {
  @override
  Future<List<ClassificationRule>> build() =>
      ref.read(repositoriesProvider).rules.classificationRules();

  /// A new id for a rule.
  String newId() => 'rule-${ref.read(appServicesProvider).ids.newId()}';

  /// Saves [rule]: a new one goes last, an existing one keeps its place.
  Future<void> save(ClassificationRule rule) async {
    final rules = await future;
    final index = rules.indexWhere((r) => r.id == rule.id);
    final ordered = [...rules];
    if (index < 0) {
      ordered.add(rule);
    } else {
      ordered[index] = rule;
    }
    await _saveInOrder(ordered);
  }

  Future<void> remove(String id) async {
    await ref.read(repositoriesProvider).rules.removeClassificationRule(id);
    state = AsyncData(await build());
  }

  /// Moves the rule with [id] one place up (earlier, applies first) or
  /// down.
  Future<void> move(String id, {required bool up}) async {
    final ordered = [...await future];
    final index = ordered.indexWhere((r) => r.id == id);
    final other = up ? index - 1 : index + 1;
    if (index < 0 || other < 0 || other >= ordered.length) {
      return;
    }
    final moved = ordered[index];
    ordered[index] = ordered[other];
    ordered[other] = moved;
    await _saveInOrder(ordered);
  }

  /// Gives the rules the priorities of their order: 0, 10, 20, ...
  Future<void> _saveInOrder(List<ClassificationRule> ordered) async {
    final repository = ref.read(repositoriesProvider).rules;
    for (var i = 0; i < ordered.length; i++) {
      final rule = ordered[i];
      await repository.saveClassificationRule(
        ClassificationRule(
          id: rule.id,
          category: rule.category,
          priority: i * 10,
          extensions: rule.extensions,
          nameContains: rule.nameContains,
          folder: rule.folder,
          sourceId: rule.sourceId,
        ),
      );
    }
    state = AsyncData(await build());
  }
}

final userRulesProvider =
    AsyncNotifierProvider<UserRules, List<ClassificationRule>>(UserRules.new);

/// The folders directly inside a folder of the shared storage, for
/// choosing one; `null` if it cannot be read.
final childFoldersProvider = FutureProvider.autoDispose
    .family<List<String>?, LogicalPath>((ref, folder) async {
      final source = await ref
          .read(repositoriesProvider)
          .sources
          .byId(AppController.storageId);
      if (source == null) {
        return null;
      }
      return ref.read(appServicesProvider).childFolders(source, folder);
    });
