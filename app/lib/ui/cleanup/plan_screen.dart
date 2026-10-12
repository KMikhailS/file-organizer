import 'dart:async';

import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/l10n/app_localizations.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/ui/cleanup/plan_texts.dart';
import 'package:file_organizer/ui/cleanup/thumbnail.dart';
import 'package:file_organizer/ui/texts/path_text.dart';
import 'package:file_organizer/ui/texts/reason_texts.dart';
import 'package:file_organizer/ui/texts/size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The plan for review and approval (`docs/stage2_android.md`, section 9,
/// screen 4): groups with check boxes, their files on demand, what stays
/// untouched, warnings, "Decline" and "Apply".
///
/// One lazy list: an open group with thousands of files builds only the
/// rows on screen.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({required this.review, super.key});

  final PlanReview review;

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  /// Open groups, by source and group key; `null` key: the unresolved files.
  final Set<(SourceId, String?)> _open = {};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final review = widget.review;
    final actions = ref.read(cleanupActionsProvider);
    if (review.isEmpty) {
      return _EmptyPlan(onBack: actions.dismiss);
    }
    final rows = _rows(review);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.planTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: rows.length,
        itemBuilder: (context, i) => rows[i](context),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: actions.dismiss,
                  child: Text(l.declineButton),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: review.canApply
                      ? () => unawaited(actions.apply())
                      : null,
                  child: Text(l.applyButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<WidgetBuilder> _rows(PlanReview review) {
    final rows = <WidgetBuilder>[(context) => _Summary(review: review)];
    final actions = ref.read(cleanupActionsProvider);
    for (final source in review.sources) {
      for (final group in source.groups) {
        final (SourceId, String?) key = (source.source.id, group.key);
        final open = _open.contains(key);
        rows.add(
          (context) => _GroupHeader(
            group: group,
            open: open,
            onToggleOpen: () =>
                setState(() => open ? _open.remove(key) : _open.add(key)),
            onApproval: (approved) => actions.setGroupApproval(
              source.source.id,
              group.key,
              approved: approved,
            ),
          ),
        );
        if (open) {
          for (final file in group.files) {
            rows.add(
              (context) => _FileRow(
                source: source.source,
                file: file,
                onApproval: (approved) => actions.setFileApproval(
                  source.source.id,
                  file.index,
                  approved: approved,
                ),
              ),
            );
          }
        }
      }
      if (source.unresolved.isNotEmpty) {
        final (SourceId, String?) key = (source.source.id, null);
        final open = _open.contains(key);
        rows.add(
          (context) => _UnresolvedHeader(
            count: source.unresolved.length,
            open: open,
            onToggleOpen: () =>
                setState(() => open ? _open.remove(key) : _open.add(key)),
          ),
        );
        if (open) {
          for (final file in source.unresolved) {
            rows.add((context) => _UnresolvedRow(file: file));
          }
        }
      }
      if (source.untouchedCopies > 0) {
        rows.add(
          (context) => _InfoCard(
            icon: Icons.folder_special_outlined,
            text: AppLocalizations.of(context)
                .untouchedCopies(source.untouchedCopies),
          ),
        );
      }
    }
    final warnings = _warnings(review);
    if (warnings.isNotEmpty) {
      rows.add((context) => _Warnings(lines: warnings(context)));
    }
    return rows;
  }

  /// The warnings of [review], or an empty list if there are none.
  _WarningLines _warnings(PlanReview review) {
    final inaccessible = review.sources.fold(
      0,
      (n, s) => n + s.inaccessibleFolders.length,
    );
    final unhashed = review.sources.fold(
      0,
      (n, s) => n + s.unhashedFiles.length,
    );
    final unavailable = review.unavailableSources.length;
    return _WarningLines(
      inaccessible: inaccessible,
      unhashed: unhashed,
      unavailable: unavailable,
    );
  }
}

/// The counts behind the warnings card.
final class _WarningLines {
  const _WarningLines({
    required this.inaccessible,
    required this.unhashed,
    required this.unavailable,
  });

  final int inaccessible;
  final int unhashed;
  final int unavailable;

  bool get isNotEmpty => inaccessible + unhashed + unavailable > 0;

  List<String> call(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      if (inaccessible > 0) l.warningInaccessible(inaccessible),
      if (unhashed > 0) l.warningUnhashed(unhashed),
      if (unavailable > 0) l.warningUnavailableSources(unavailable),
    ];
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.review});

  final PlanReview review;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: review.canApply
            ? [
                Text(
                  l.planSummaryFiles(review.approvedFiles),
                  style: theme.textTheme.titleMedium,
                ),
                if (review.approvedBytes > 0)
                  Text(l.planSummaryFreed(sizeText(l, review.approvedBytes))),
              ]
            : [Text(l.planNothingSelected, style: theme.textTheme.titleMedium)],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.group,
    required this.open,
    required this.onToggleOpen,
    required this.onApproval,
  });

  final PlanGroupView group;
  final bool open;
  final VoidCallback onToggleOpen;
  final ValueChanged<bool> onApproval;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final approval = group.approval;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListTile(
        leading: Checkbox(
          tristate: true,
          value: switch (approval) {
            Approval.all => true,
            Approval.none => false,
            Approval.some => null,
          },
          // A partly approved group is approved as a whole first.
          onChanged: (_) => onApproval(approval != Approval.all),
        ),
        title: Text(groupTitle(l, group)),
        subtitle: group.kind is DuplicatesGroup
            ? Text(l.groupDuplicatesHint)
            : null,
        trailing: IconButton(
          tooltip: open ? l.hideFiles : l.showFiles,
          icon: Icon(open ? Icons.expand_less : Icons.expand_more),
          onPressed: onToggleOpen,
        ),
        onTap: onToggleOpen,
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.source,
    required this.file,
    required this.onApproval,
  });

  final Source source;
  final OperationView file;
  final ValueChanged<bool> onApproval;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final folder = file.from.parent;
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 16),
      child: CheckboxListTile(
        value: file.approved,
        onChanged: (approved) => onApproval(approved ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        secondary: Thumbnail(source: source, file: file),
        title: Text(fileName(file.from), overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (folder != null) l.fileFrom(pathText(folder)),
            operationReasonText(l, file.reason),
            sizeText(l, file.size),
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _UnresolvedHeader extends StatelessWidget {
  const _UnresolvedHeader({
    required this.count,
    required this.open,
    required this.onToggleOpen,
  });

  final int count;
  final bool open;
  final VoidCallback onToggleOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: Text(l.unresolvedTitle(count)),
        subtitle: Text(l.unresolvedText),
        trailing: Icon(open ? Icons.expand_less : Icons.expand_more),
        onTap: onToggleOpen,
      ),
    );
  }
}

class _UnresolvedRow extends StatelessWidget {
  const _UnresolvedRow({required this.file});

  final UnresolvedFile file;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 16),
      child: ListTile(
        title: Text(fileName(file.path), overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            pathText(file.path),
            classificationReasonText(l, file.reason),
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}

class _Warnings extends StatelessWidget {
  const _Warnings({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              spacing: 8,
              children: [
                const Icon(Icons.warning_amber_outlined),
                Expanded(
                  child: Text(
                    l.warningsTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            ...lines.map(Text.new),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(l.planEmptyTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l.planEmptyText),
              const SizedBox(height: 24),
              FilledButton(onPressed: onBack, child: Text(l.back)),
            ],
          ),
        ),
      ),
    );
  }
}
