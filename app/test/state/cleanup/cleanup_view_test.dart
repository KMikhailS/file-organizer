import 'dart:async';

import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/planner/planner.dart';
import 'package:file_organizer/core/workflow/workflow.dart';
import 'package:file_organizer/state/app_controller.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:file_organizer/state/cleanup/cleanup_view_of.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_native.dart';
import '../../support/fs/in_memory_file_source.dart';
import '../../support/scenarios.dart';

/// The cleanup screens' view of the workflow (docs/stage2_android.md, 5.19)
/// on a fake device with a typical Download folder, duplicate photos and
/// two equal files in the user's own Documents.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDevice device;
  late InMemoryFileSource files;
  late ProviderContainer container;

  setUp(() async {
    device = FakeDevice(
      files: (source) => files = InMemoryFileSource(sourceId: source.id)
        ..withTypicalDownloadFolder()
        ..withPhoneDuplicatePhotos()
        ..addFile('Documents/Tax/receipt.pdf', text: 'receipt 42')
        ..addFile('Documents/Old/receipt copy.pdf', text: 'receipt 42'),
    )..access.allFiles = true;
    await device.fixFolderNames();
    container = ProviderContainer(overrides: device.overrides);
    addTearDown(container.dispose);
    container.listen(cleanupViewProvider, (_, _) {});
    await container.read(appControllerProvider.notifier).start();
  });

  CleanupView view() => container.read(cleanupViewProvider);
  CleanupWorkflow workflow() => container.read(workflowProvider);

  /// The view follows the workflow through its stream of states; an
  /// execution emits many of them.
  Future<CleanupView> settledView() async {
    for (
      var i = 0;
      i < 100 &&
          !identical(
            container.read(workflowStateProvider).value,
            workflow().state,
          );
      i++
    ) {
      await pumpEventQueue();
    }
    return view();
  }

  CleanupActions actions() => container.read(cleanupActionsProvider);

  Future<PlanReview> plan() async {
    await actions().plan();
    await pumpEventQueue();
    return view() as PlanReview;
  }

  test('idle is at home', () {
    expect(view(), isA<AtHome>());
    expect(cleanupViewOf(null), isA<AtHome>());
  });

  test('the plan: groups by kind, files without folders, approvals', () async {
    final review = await plan();
    final source = review.sources.single;
    final kinds = [for (final g in source.groups) g.kind];
    expect(kinds.first, isA<DuplicatesGroup>());
    final folders = [
      for (final kind in kinds)
        if (kind case MoveGroup(:final folder)) folder.value,
    ];
    expect(folders, containsAll(['Documents', 'Photos/2024', 'Music']));

    final planned = (workflow().state as PlanReady).plans.single.plan;
    for (final group in source.groups) {
      expect(group.approval, Approval.all);
      for (final file in group.files) {
        final operation = planned.operations[file.index];
        expect(operation.type, isNot(OperationType.mkdir));
        expect(operation.fromPath, file.from);
        expect(operation.groupKey, group.key);
      }
    }
    final duplicates = source.groups.first;
    expect(
      duplicates.files.every((f) => f.type == OperationType.quarantine),
      isTrue,
    );
    expect(duplicates.files.every((f) => f.to == null), isTrue);
    expect(duplicates.bytes, greaterThan(0));
    expect(review.approvedFiles, planned.summary.fileCount);
    expect(review.approvedBytes, planned.summary.reclaimableBytes);
    expect(review.canApply, isTrue);
  });

  test('media files are marked for thumbnails', () async {
    final review = await plan();
    final all = [for (final g in review.sources.single.groups) ...g.files];
    final byName = {for (final f in all) f.from.segments.last: f.media};
    expect(byName['photo.png'], isTrue);
    expect(byName['IMG_20240518_093000 (1).jpg'], isTrue);
    expect(byName['song.mp3'], isFalse);
    expect(byName['Report.DOCX'], isFalse);
  });

  test('unresolved files with their reason; copies in own folders are '
      'counted, never planned', () async {
    final source = (await plan()).sources.single;
    final unresolved = {
      for (final f in source.unresolved) f.path.value: f.reason,
    };
    expect(unresolved['Download/data.xyz'], const UnknownExtension('xyz'));
    expect(unresolved['Download/README'], const NoExtension());
    expect(source.untouchedCopies, 1);
    final planned = [
      for (final g in source.groups) ...g.files.map((f) => f.from.value),
    ];
    expect(planned.where((p) => p.startsWith('Documents/')), isEmpty);
  });

  test('approving a group or a file; the totals follow', () async {
    var review = await plan();
    final source = review.sources.single.source.id;
    final duplicates = review.sources.single.groups.first;

    actions().setGroupApproval(source, duplicates.key, approved: false);
    review = await settledView() as PlanReview;
    expect(review.sources.single.groups.first.approval, Approval.none);
    expect(review.approvedBytes, 0);

    actions().setFileApproval(
      source,
      duplicates.files.first.index,
      approved: true,
    );
    review = await settledView() as PlanReview;
    expect(review.sources.single.groups.first.approval, Approval.some);
    expect(review.approvedBytes, duplicates.files.first.size);

    for (final group in review.sources.single.groups) {
      actions().setGroupApproval(source, group.key, approved: false);
    }
    review = await settledView() as PlanReview;
    expect(review.approvedFiles, 0);
    expect(review.canApply, isFalse);
  });

  test('apply executes only what is approved, then shows the result', () async {
    final review = await plan();
    final source = review.sources.single.source.id;
    final music = review.sources.single.groups.firstWhere(
      (g) => switch (g.kind) {
        MoveGroup(:final folder) => folder.value == 'Music',
        DuplicatesGroup() => false,
      },
    );
    actions().setGroupApproval(source, music.key, approved: false);
    await actions().apply();
    final result = await settledView() as CleanupResult;
    expect(result.kind, ResultKind.completed);
    expect(result.canUndo, isTrue);
    expect(result.totals.done, result.totals.total);
    expect(workflow().state, isA<Completed>());
    expect(files.isFile('Download/song.mp3'), isTrue);
    expect(files.isFile('Music/song.mp3'), isFalse);
    expect(files.isFile('Download/notes.txt'), isFalse);
    expect(files.isFile('Documents/Tax/receipt.pdf'), isTrue);
    expect(files.isFile('Documents/Old/receipt copy.pdf'), isTrue);

    actions().dismiss();
    expect(await settledView(), isA<AtHome>());
  });

  test('declining goes home and changes nothing', () async {
    await plan();
    final before = files.snapshot();
    actions().dismiss();
    expect(await settledView(), isA<AtHome>());
    expect(files.snapshot(), before);
  });

  test('cancel shows "cancelling" until the work stops', () async {
    final seen = <CleanupView>[];
    container.listen(cleanupViewProvider, (_, next) => seen.add(next));
    var cancelled = false;
    files.onHashBlock = (_, _) {
      if (!cancelled) {
        cancelled = true;
        actions().cancel();
      }
    };
    await actions().plan();
    await pumpEventQueue();
    expect(seen.whereType<InProgress>().where((p) => p.cancelling), isNotEmpty);
    expect(view(), isA<AtHome>());
    expect(container.read(cancelRequestProvider), isFalse);
  });

  test('cancel when nothing runs does nothing', () {
    actions().cancel();
    expect(container.read(cancelRequestProvider), isFalse);
  });

  test('"Cancel" in the notification cancels the work', () async {
    var tapped = false;
    files.onHashBlock = (_, _) {
      if (!tapped) {
        tapped = true;
        unawaited(device.native.onCancelRequested());
      }
    };
    await actions().plan();
    await pumpEventQueue();
    expect(tapped, isTrue);
    expect(workflow().state, isA<Idle>());
    expect(device.foreground.calls.last, 'stop');
  });

  test('the group key of the planner round-trips', () {
    final folder = LogicalPath('Photos/2024');
    expect((groupKind(Planner.moveGroup(folder)) as MoveGroup).folder, folder);
    expect(groupKind(Planner.duplicatesGroup), isA<DuplicatesGroup>());
    expect(() => groupKind('other'), throwsArgumentError);
  });

  test('failures and interrupted cleanups have their views', () {
    expect(cleanupViewOf(const Failed('boom')), isA<PlanFailed>());
    expect(
      cleanupViewOf(Interrupted(const [], unavailable: const [SessionId('s')])),
      isA<InterruptedCleanup>().having((v) => v.unavailable, 'unavailable', 1),
    );
  });
}
