import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/ui/texts/path_text.dart';
import 'package:file_organizer/ui/texts/problem_texts.dart';
import 'package:flutter/material.dart';

/// One problem of a cleanup: the file and why; "needs attention" stands out.
class ProblemTile extends StatelessWidget {
  const ProblemTile({required this.problem, super.key});

  final ProblemView problem;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final attention = problem.needsAttention;
    final color = attention ? theme.colorScheme.error : null;
    return ListTile(
      leading: Icon(
        attention ? Icons.report_outlined : Icons.info_outline,
        color: color,
      ),
      title: Text(pathText(problem.path), style: TextStyle(color: color)),
      // The text of "needs attention" says so itself.
      subtitle: Text(operationProblemText(l, problem.problem)),
    );
  }
}
