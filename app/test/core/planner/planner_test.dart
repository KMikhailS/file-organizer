import 'package:file_organizer/core/classify/classify.dart';
import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/planner/planning.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/zones/zones.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/layout_fixtures.dart';
import '../../support/model_fixtures.dart';
import '../../support/pipeline_harness.dart';
import '../../support/scenarios.dart';

void main() {
  group('typical Download folder', () {
    late Plan plan;
    setUp(() async {
      plan = await PipelineHarness(
        InMemoryFileSource()..withTypicalDownloadFolder(),
      ).readyPlan();
    });

    test('the whole plan, in order', () {
      const shot = 'Screenshot_20240301-120000.png';
      const img = 'IMG_20240512_101500.jpg';
      expect(describe(plan), [
        'quarantine Download/invoice_2024 (1).pdf',
        'mkdir Архивы',
        'move Download/backup.zip -> Архивы/backup.zip',
        'mkdir Видео',
        'mkdir Видео/2024',
        'move Download/holiday-edit.mp4 -> Видео/2024/holiday-edit.mp4',
        'move Download/holiday.mp4 -> Видео/2024/holiday.mp4',
        'mkdir Документы',
        'move Download/Report.DOCX -> Документы/Report.DOCX',
        'move Download/empty.txt -> Документы/empty.txt',
        'move Download/invoice_2024.pdf -> Документы/invoice_2024.pdf',
        'move Download/notes.txt -> Документы/notes.txt',
        'move Download/table.xlsx -> Документы/table.xlsx',
        'mkdir Музыка',
        'move Download/song.mp3 -> Музыка/song.mp3',
        'mkdir Скриншоты',
        'mkdir Скриншоты/2024',
        'move Download/$shot -> Скриншоты/2024/$shot',
        'mkdir Установщики',
        'move Download/app-release.apk -> Установщики/app-release.apk',
        'move Download/setup.exe -> Установщики/setup.exe',
        'mkdir Фото',
        'mkdir Фото/2023',
        'move Download/photo.png -> Фото/2023/photo.png',
        'mkdir Фото/2024',
        'move Download/$img -> Фото/2024/$img',
      ]);
    });

    test('lists unresolved files and duplicate groups', () {
      expect(plan.unresolved.map((f) => f.path.value), [
        'Download/README',
        'Download/data.xyz',
      ]);
      expect(plan.duplicateGroups, hasLength(1));
    });

    test('groups operations, approves them and gives reasons', () {
      expect(plan.groups.map((g) => g.key), [
        Planner.duplicatesGroup,
        'move:Архивы',
        'move:Видео/2024',
        'move:Документы',
        'move:Музыка',
        'move:Скриншоты/2024',
        'move:Установщики',
        'move:Фото/2023',
        'move:Фото/2024',
      ]);
      expect(plan.operations.map((o) => o.approved), everyElement(isTrue));
      final quarantine = plan.operations.first;
      expect(
        quarantine.reason,
        DuplicateOf(LogicalPath('Download/invoice_2024.pdf')),
      );
      expect(
        plan.operations
            .firstWhere((o) => o.fromPath?.value == 'Download/notes.txt')
            .reason,
        const Classified(ByExtension('txt')),
      );
      expect(
        plan.operations.firstWhere((o) => o.type == OperationType.mkdir).reason,
        isA<FolderFor>(),
      );
    });

    test('fingerprints come from the index', () {
      final quarantine = plan.operations.first;
      expect(quarantine.fingerprint!.fullHash, isNotNull);
      expect(quarantine.fingerprint!.modifiedAt, DateTime.utc(2024, 2, 1, 12));
    });

    test('summary', () {
      expect(plan.summary.fileCount, 15);
      expect(plan.summary.reclaimableBytes, 'invoice 2024: 1250.00 EUR'.length);
    });
  });

  test('phone: only the received copies go to quarantine', () async {
    final plan = await PipelineHarness(phoneStorage()).readyPlan();
    const whatsApp = 'Android/media/com.whatsapp/WhatsApp/Media';
    expect(describe(plan), [
      'quarantine $whatsApp/WhatsApp Images/IMG-20230715-WA0001.jpg',
      'quarantine Telegram/Telegram Images/photo_2024-02-04.jpg',
      'quarantine Download/IMG_20240518_093000 (1).jpg',
    ]);
  });

  test('an organized archive gets an empty plan', () async {
    final plan = await PipelineHarness(
      InMemoryFileSource()..withOrganizedDocumentArchive(),
    ).readyPlan();
    expect(plan.isEmpty, isTrue);
  });

  group('duplicates outside chaos zones are never touched', () {
    Future<Plan> planFor(List<(String, DateTime)> copies) {
      final fs = InMemoryFileSource();
      for (final (path, time) in copies) {
        fs.addFile(path, text: 'same', modifiedAt: time);
      }
      return PipelineHarness(fs).readyPlan();
    }

    final t1 = DateTime.utc(2020);
    final t2 = DateTime.utc(2021);
    final t3 = DateTime.utc(2022);

    test('all copies in organized folders: shown, no operations', () async {
      final plan = await planFor([
        ('Documents/a.pdf', t1),
        ('Archive/a.pdf', t2),
      ]);
      expect(plan.operations, isEmpty);
      expect(plan.duplicateGroups.single.files, hasLength(2));
    });

    test('mixed: only the copy in the chaos zone', () async {
      final plan = await planFor([
        ('Documents/a.pdf', t1),
        ('Archive/a.pdf', t2),
        ('Download/a.pdf', t3),
      ]);
      expect(describe(plan), ['quarantine Download/a.pdf']);
      expect(plan.duplicateGroups.single.extras, hasLength(2));
    });

    test('copies in target folders stay too', () async {
      final plan = await planFor([
        ('Фото/2023/x.jpg', t1),
        ('Фото/2024/x.jpg', t2),
        ('Download/x.jpg', t3),
      ]);
      expect(describe(plan), ['quarantine Download/x.jpg']);
    });

    test('the keeper is moved when all copies are in chaos', () async {
      final plan = await planFor([
        ('Download/a.pdf', t1),
        ('Desktop/a (1).pdf', t2),
      ]);
      expect(describe(plan), [
        'quarantine Desktop/a (1).pdf',
        'mkdir Документы',
        'move Download/a.pdf -> Документы/a.pdf',
      ]);
    });
  });

  group('name conflicts', () {
    test('with files already in the target folder', () async {
      final fs = InMemoryFileSource()
        ..addFile('Документы/notes.txt', text: 'old')
        ..addFile('Документы/notes (2).txt', text: 'older')
        ..addFile('Download/notes.txt', text: 'new');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'move Download/notes.txt -> Документы/notes (3).txt',
      ]);
    });

    test('within one plan', () async {
      final fs = InMemoryFileSource()
        ..addFile('Download/a.pdf', text: 'one')
        ..addFile('Desktop/a.pdf', text: 'two')
        ..addFile('A.PDF', text: 'three');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'mkdir Документы',
        'move A.PDF -> Документы/A.PDF',
        'move Desktop/a.pdf -> Документы/a (2).pdf',
        'move Download/a.pdf -> Документы/a (3).pdf',
      ]);
    });

    test('regardless of case on phone storage', () async {
      final fs = InMemoryFileSource(caseSensitive: false)
        ..addFile('документы/REPORT.pdf', text: 'old')
        ..addFile('Download/report.pdf', text: 'new');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'move Download/report.pdf -> Документы/report (2).pdf',
      ]);
    });
  });

  group('folders', () {
    test('an existing empty folder is not created again', () async {
      final fs = InMemoryFileSource()
        ..addDir('Документы')
        ..addFile('Download/a.pdf');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'move Download/a.pdf -> Документы/a.pdf',
      ]);
    });

    test('a folder that cannot be checked gets no moves', () async {
      final fs = InMemoryFileSource()
        ..addDir('Фото')
        ..addFile('Download/a.jpg', modifiedAt: DateTime.utc(2024))
        ..addFile('Download/b.pdf')
        ..denyAccess('Фото');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'mkdir Документы',
        'move Download/b.pdf -> Документы/b.pdf',
      ]);
    });

    test('a custom template root', () async {
      final fs = InMemoryFileSource()..addFile('Download/a.pdf');
      final plan = await PipelineHarness(
        fs,
        template: russianTemplate(root: p('Sorted')),
      ).readyPlan();
      expect(describe(plan), [
        'mkdir Sorted',
        'mkdir Sorted/Документы',
        'move Download/a.pdf -> Sorted/Документы/a.pdf',
      ]);
    });
  });

  group('source capabilities', () {
    test('iOS Photos: duplicates go to the album, nothing moves', () async {
      final fs = InMemoryFileSource(capabilities: iosPhotosCapabilities)
        ..addFile('IMG_1.HEIC', text: 'same', modifiedAt: DateTime.utc(2020))
        ..addFile('IMG_2.HEIC', text: 'same', modifiedAt: DateTime.utc(2021))
        ..addFile('IMG_3.HEIC', text: 'other');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'addToAlbum IMG_2.HEIC',
      ]);
    });

    test('without quarantine or album: duplicates are only shown', () async {
      final fs =
          InMemoryFileSource(
              capabilities: const SourceCapabilities(
                canMove: true,
                canMkdir: true,
              ),
            )
            ..addFile(
              'Download/a.pdf',
              text: 'same',
              modifiedAt: DateTime.utc(2020),
            )
            ..addFile(
              'Download/b.pdf',
              text: 'same',
              modifiedAt: DateTime.utc(2021),
            );
      final plan = await PipelineHarness(fs).readyPlan();
      expect(describe(plan), [
        'mkdir Документы',
        'move Download/a.pdf -> Документы/a.pdf',
      ]);
      expect(plan.duplicateGroups, hasLength(1));
    });

    test('without mkdir: only moves into existing folders', () async {
      final fs =
          InMemoryFileSource(
              capabilities: const SourceCapabilities(canMove: true),
            )
            ..addDir('Документы')
            ..addFile('Download/a.pdf')
            ..addFile('Download/b.mp3');
      expect(describe(await PipelineHarness(fs).readyPlan()), [
        'move Download/a.pdf -> Документы/a.pdf',
      ]);
    });
  });

  group('zones', () {
    test('a folder the user marked organized is left alone', () async {
      final fs = InMemoryFileSource()..withTypicalDownloadFolder();
      final plan = await PipelineHarness(
        fs,
        overrides: [
          ZoneOverride(
            sourceId: fs.sourceId,
            folder: p('Download'),
            zone: Zone.organized,
          ),
        ],
      ).readyPlan();
      expect(plan.isEmpty, isTrue);
    });

    test(
      'a folder the user marked chaos is cleaned with its subfolders',
      () async {
        final fs = InMemoryFileSource()..addFile('Desktop/Inbox/x/a.pdf');
        final plan = await PipelineHarness(
          fs,
          overrides: [
            ZoneOverride(
              sourceId: fs.sourceId,
              folder: p('Desktop/Inbox'),
              zone: Zone.chaos,
            ),
          ],
        ).readyPlan();
        expect(describe(plan), [
          'mkdir Документы',
          'move Desktop/Inbox/x/a.pdf -> Документы/a.pdf',
        ]);
      },
    );
  });

  test('the classifier decides; AI-style subfolders are honored', () async {
    final fs = InMemoryFileSource()..addFile('Download/a.zzz');
    final plan = await PipelineHarness(
      fs,
      classifier: ClassificationPipeline(
        rules: RuleClassifier(),
        ai: _SubfolderAi(),
      ),
    ).readyPlan();
    expect(describe(plan), [
      'mkdir Документы',
      'mkdir Документы/Налоги',
      'move Download/a.zzz -> Документы/Налоги/a.zzz',
    ]);
  });

  test('inputs must belong to the source', () async {
    final fs = InMemoryFileSource();
    final planner = Planner(
      classifier: RuleClassifier(),
      template: russianTemplate(),
    );
    expect(
      () => planner.plan(
        source: fs,
        files: const [],
        zones: ZoneMap(sourceId: const SourceId('other')),
      ),
      throwsArgumentError,
    );
    expect(
      () => planner.plan(
        source: fs,
        files: [fileEntry('a', sourceId: const SourceId('other'))],
        zones: ZoneMap(sourceId: fs.sourceId),
      ),
      throwsArgumentError,
    );
  });
}

final class _SubfolderAi implements Classifier {
  @override
  Future<List<Classification>> classify(
    List<ClassificationRequest> requests,
  ) async => [
    for (final _ in requests)
      Classification(
        category: Category.documents,
        subfolder: LogicalPath('Налоги'),
        confidence: 0.8,
        origin: ClassificationOrigin.ai,
        reason: const AiSuggestion(),
      ),
  ];
}
