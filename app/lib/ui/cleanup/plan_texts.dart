import 'package:file_organizer/core/model/logical_path.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/ui/texts/size_text.dart';

/// A folder as the plan shows it: `Photos / 2024`.
String folderText(LogicalPath folder) =>
    folder.isRoot ? '/' : folder.segments.join(' / ');

/// The title of a plan group: `Duplicates: 3 files, 12 MB`, `To Photos /
/// 2024: 41`.
String groupTitle(AppLocalizations l, PlanGroupView group) =>
    switch (group.kind) {
      DuplicatesGroup() => l.groupDuplicates(
        group.files.length,
        sizeText(l, group.bytes),
      ),
      MoveGroup(:final folder) => l.groupMoveTo(
        folderText(folder),
        group.files.length,
      ),
    };

/// The name of the file at [path].
String fileName(LogicalPath path) => path.segments.last;
