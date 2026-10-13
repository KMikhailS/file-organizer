import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks before an undo of a whole cleanup or a group (decision of task 14):
/// "Bring the files back?". With [files], says how many come back.
Future<bool> confirmUndo(BuildContext context, {int? files}) async {
  final l = AppLocalizations.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.undoConfirmTitle),
      content: Text(
        files == null ? l.undoConfirmAll : l.undoConfirmFiles(files),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.undoConfirmYes),
        ),
      ],
    ),
  );
  return yes ?? false;
}
