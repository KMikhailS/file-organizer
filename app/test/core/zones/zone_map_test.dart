import 'package:file_organizer/core/model/model.dart';
import 'package:file_organizer/core/ports/ports.dart';
import 'package:file_organizer/core/zones/zones.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fs/in_memory_file_source.dart';
import '../../support/model_fixtures.dart';
import '../../support/scenarios.dart';

void main() {
  ZoneMap zonesOf({
    ZoneConfig config = const ZoneConfig(),
    List<(String, Zone)> overrides = const [],
    List<String> files = const [],
  }) => ZoneMap(
    sourceId: testSource,
    config: config,
    overrides: [
      for (final (folder, zone) in overrides)
        ZoneOverride(sourceId: testSource, folder: p(folder), zone: zone),
    ],
    files: files.map(fileEntry),
  );

  /// Checks the decision for each folder: (folder, reason, decided by).
  void expectFolders(
    ZoneMap zones,
    List<(String folder, ZoneReason reason, String decidedBy)> cases,
  ) {
    for (final (folder, reason, decidedBy) in cases) {
      expect(
        zones.decideFolder(p(folder)),
        ZoneDecision(reason, p(decidedBy)),
        reason: 'folder "$folder"',
      );
    }
  }

  group('built-in exclusions', () {
    final zones = zonesOf(config: ZoneConfig(appFolders: {p('.organizer')}));

    test('hidden folders', () {
      expectFolders(zones, [
        ('.config', ZoneReason.hiddenFolder, '.config'),
        ('Download/.cache', ZoneReason.hiddenFolder, 'Download/.cache'),
        ('Documents/.git/objects', ZoneReason.hiddenFolder, 'Documents/.git'),
      ]);
    });

    test('development folders, anywhere', () {
      expectFolders(zones, [
        ('node_modules', ZoneReason.developmentFolder, 'node_modules'),
        (
          'a/b/node_modules/x',
          ZoneReason.developmentFolder,
          'a/b/node_modules',
        ),
        ('Work/build', ZoneReason.developmentFolder, 'Work/build'),
        ('Work/target/classes', ZoneReason.developmentFolder, 'Work/target'),
        ('Work/__pycache__', ZoneReason.developmentFolder, 'Work/__pycache__'),
        (
          'Dev/App.xcodeproj',
          ZoneReason.developmentFolder,
          'Dev/App.xcodeproj',
        ),
      ]);
    });

    test('system folders', () {
      expectFolders(zones, [
        ('Android/data', ZoneReason.systemFolder, 'Android/data'),
        ('Android/data/com.app/cache', ZoneReason.systemFolder, 'Android/data'),
        ('Android/obb', ZoneReason.systemFolder, 'Android/obb'),
        ('Users/me/AppData/Local', ZoneReason.systemFolder, 'Users/me/AppData'),
        ('Windows', ZoneReason.systemFolder, 'Windows'),
        ('Program Files', ZoneReason.systemFolder, 'Program Files'),
        (
          'Program Files (x86)/X',
          ZoneReason.systemFolder,
          'Program Files (x86)',
        ),
        ('Library/Caches', ZoneReason.systemFolder, 'Library'),
        (r'$Recycle.Bin', ZoneReason.systemFolder, r'$Recycle.Bin'),
      ]);
    });

    test('root-only system names are fine deeper down', () {
      expect(zones.zoneOfFolder(p('Music/Library')), Zone.organized);
      expect(zones.zoneOfFolder(p('Photos/Windows')), Zone.organized);
      expect(zones.zoneOfFolder(p('Android/media')), Zone.organized);
    });

    test('app folders', () {
      expectFolders(zones, [
        ('.organizer/q', ZoneReason.hiddenFolder, '.organizer'),
      ]);
      final visible = zonesOf(
        config: ZoneConfig(appFolders: {p('File Organizer/Quarantine')}),
      );
      expectFolders(visible, [
        (
          'File Organizer/Quarantine/s1',
          ZoneReason.appFolder,
          'File Organizer/Quarantine',
        ),
      ]);
    });

    test('project folders, found by their build files', () {
      final zones = zonesOf(
        files: [
          'Desktop/my-app/pubspec.yaml',
          'Desktop/my-app/lib/main.dart',
          'Work/site/package.json',
          'Work/Tool/Tool.sln',
          'Work/notes.txt',
        ],
      );
      expectFolders(zones, [
        ('Desktop/my-app', ZoneReason.projectFolder, 'Desktop/my-app'),
        ('Desktop/my-app/lib', ZoneReason.projectFolder, 'Desktop/my-app'),
        ('Work/site', ZoneReason.projectFolder, 'Work/site'),
        ('Work/Tool', ZoneReason.projectFolder, 'Work/Tool'),
        ('Work', ZoneReason.notAChaosFolder, 'Work'),
      ]);
      expect(zones.projectRoots, {
        p('Desktop/my-app'),
        p('Work/site'),
        p('Work/Tool'),
      });
    });

    test('a stray build file does not exclude a chaos folder', () {
      final zones = zonesOf(
        files: [
          'package.json',
          'Download/Makefile',
          'Desktop/pom.xml',
          'Telegram/Telegram Documents/setup.py',
        ],
      );
      expect(zones.projectRoots, isEmpty);
      expect(zones.zoneOfFolder(LogicalPath.root), Zone.chaos);
      expect(zones.zoneOfFolder(p('Download')), Zone.chaos);
      expect(zones.zoneOfFolder(p('Desktop')), Zone.chaos);
    });

    test('match regardless of case', () {
      expectFolders(zones, [
        ('NODE_MODULES', ZoneReason.developmentFolder, 'NODE_MODULES'),
        ('android/DATA', ZoneReason.systemFolder, 'android/DATA'),
      ]);
    });
  });

  group('file exclusions', () {
    final zones = zonesOf();

    test('hidden, system, unfinished and lock files', () {
      const cases = {
        'Download/.DS_Store': ZoneReason.hiddenFile,
        '.profile': ZoneReason.hiddenFile,
        'Download/desktop.ini': ZoneReason.systemFile,
        'Download/Thumbs.db': ZoneReason.systemFile,
        'Download/movie.mkv.crdownload': ZoneReason.incompleteFile,
        'Download/video.part': ZoneReason.incompleteFile,
        'Download/data.TMP': ZoneReason.incompleteFile,
        r'Desktop/~$report.docx': ZoneReason.incompleteFile,
      };
      for (final MapEntry(key: file, value: reason) in cases.entries) {
        expect(
          zones.decideFile(p(file)),
          ZoneDecision(reason, p(file)),
          reason: file,
        );
      }
    });

    test('other files take the zone of their folder', () {
      expect(
        zones.decideFile(p('Download/report.pdf')),
        ZoneDecision(ZoneReason.downloadsOrDesktop, p('Download')),
      );
      expect(zones.zoneOfFile(p('Documents/a.pdf')), Zone.organized);
      expect(zones.zoneOfFile(p('a.pdf')), Zone.chaos);
      expect(zones.zoneOfFile(p('node_modules/x/a.js')), Zone.excluded);
    });

    test('the root is not a file', () {
      expect(() => zones.decideFile(LogicalPath.root), throwsArgumentError);
    });
  });

  group('default chaos', () {
    final zones = zonesOf();

    test('files directly in the source root', () {
      expectFolders(zones, [('', ZoneReason.sourceRoot, '')]);
    });

    test('downloads and desktop folders at the root', () {
      for (final name in [
        'Download',
        'Downloads',
        'downloads',
        'Desktop',
        'Загрузки',
        'Рабочий стол',
        'Téléchargements',
      ]) {
        expectFolders(zones, [(name, ZoneReason.downloadsOrDesktop, name)]);
      }
    });

    test('only at the root: deeper ones are left alone', () {
      expectFolders(zones, [
        ('Work/Download', ZoneReason.notAChaosFolder, 'Work/Download'),
      ]);
    });

    test('subfolders of downloads and desktop are left alone', () {
      expectFolders(zones, [
        ('Download/project', ZoneReason.notAChaosFolder, 'Download/project'),
        (
          'Desktop/New folder',
          ZoneReason.notAChaosFolder,
          'Desktop/New folder',
        ),
        ('DCIM', ZoneReason.notAChaosFolder, 'DCIM'),
      ]);
    });

    test('messenger media folders with all subfolders', () {
      expectFolders(zones, [
        ('Telegram', ZoneReason.messengerMedia, 'Telegram'),
        ('Telegram/Telegram Images', ZoneReason.messengerMedia, 'Telegram'),
        (
          'WhatsApp/Media/WhatsApp Voice Notes/202401',
          ZoneReason.messengerMedia,
          'WhatsApp/Media',
        ),
        (
          'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/Sent',
          ZoneReason.messengerMedia,
          'Android/media/com.whatsapp/WhatsApp/Media',
        ),
        (
          'Android/media/org.telegram.messenger/Telegram/Telegram Video',
          ZoneReason.messengerMedia,
          'Android/media/org.telegram.messenger/Telegram',
        ),
      ]);
    });

    test('messenger app data outside the media folder is left alone', () {
      expect(zones.zoneOfFolder(p('WhatsApp/Databases')), Zone.organized);
      expect(zones.zoneOfFolder(p('WhatsApp/Media/.Statuses')), Zone.excluded);
    });

    test('Telegram Desktop downloads: files only, chat exports stay', () {
      expectFolders(zones, [
        (
          'Downloads/Telegram Desktop',
          ZoneReason.messengerDownloads,
          'Downloads/Telegram Desktop',
        ),
        (
          'Downloads/Telegram Desktop/ChatExport_2024-01-01',
          ZoneReason.notAChaosFolder,
          'Downloads/Telegram Desktop/ChatExport_2024-01-01',
        ),
        (
          'Work/Telegram Desktop',
          ZoneReason.notAChaosFolder,
          'Work/Telegram Desktop',
        ),
      ]);
    });
  });

  group('template folders', () {
    final zones = zonesOf(
      config: ZoneConfig(targetFolders: {p('Документы'), p('Фото')}),
    );

    test('are target with everything inside', () {
      expectFolders(zones, [
        ('Документы', ZoneReason.templateFolder, 'Документы'),
        ('Фото/2024', ZoneReason.templateFolder, 'Фото'),
        ('фото/2023', ZoneReason.templateFolder, 'фото'),
      ]);
    });

    test('can live under a downloads folder as template root', () {
      final nested = zonesOf(
        config: ZoneConfig(targetFolders: {p('Download/Документы')}),
      );
      expect(nested.zoneOfFolder(p('Download/Документы')), Zone.target);
      expect(nested.zoneOfFolder(p('Download')), Zone.chaos);
    });
  });

  group('user zones', () {
    test('take priority over the defaults', () {
      final zones = zonesOf(
        overrides: [
          ('Download', Zone.organized),
          ('Desktop/Inbox', Zone.chaos),
          ('Telegram', Zone.organized),
          ('Documents', Zone.excluded),
        ],
      );
      expectFolders(zones, [
        ('Download', ZoneReason.userOrganized, 'Download'),
        ('Desktop/Inbox', ZoneReason.userChaos, 'Desktop/Inbox'),
        ('Telegram/Telegram Images', ZoneReason.userOrganized, 'Telegram'),
        ('Documents/Taxes', ZoneReason.userExcluded, 'Documents'),
      ]);
    });

    test('apply to all subfolders', () {
      final zones = zonesOf(overrides: [('Desktop/Inbox', Zone.chaos)]);
      expectFolders(zones, [
        ('Desktop/Inbox/a/b', ZoneReason.userChaos, 'Desktop/Inbox'),
      ]);
    });

    test('the nearest one wins', () {
      final zones = zonesOf(
        overrides: [
          ('Documents', Zone.chaos),
          ('Documents/Taxes', Zone.organized),
          ('Documents/Taxes/Inbox', Zone.chaos),
        ],
      );
      expectFolders(zones, [
        ('Documents/Car', ZoneReason.userChaos, 'Documents'),
        ('Documents/Taxes/2023', ZoneReason.userOrganized, 'Documents/Taxes'),
        (
          'Documents/Taxes/Inbox/x',
          ZoneReason.userChaos,
          'Documents/Taxes/Inbox',
        ),
      ]);
    });

    test('can mark the whole source', () {
      final zones = zonesOf(overrides: [('', Zone.chaos)]);
      expectFolders(zones, [('DCIM/Camera', ZoneReason.userChaos, '')]);
    });

    test('never lift a built-in exclusion', () {
      final zones = zonesOf(
        overrides: [
          ('Download', Zone.chaos),
          ('Download/project/node_modules', Zone.chaos),
          ('Android/data', Zone.chaos),
          ('Work/app', Zone.chaos),
        ],
        files: ['Work/app/pubspec.yaml'],
      );
      expectFolders(zones, [
        (
          'Download/project/node_modules',
          ZoneReason.developmentFolder,
          'Download/project/node_modules',
        ),
        ('Android/data/x', ZoneReason.systemFolder, 'Android/data'),
        ('Work/app', ZoneReason.projectFolder, 'Work/app'),
        ('Download/.cache', ZoneReason.hiddenFolder, 'Download/.cache'),
      ]);
    });

    test('never turn a template folder into chaos', () {
      final zones = zonesOf(
        config: ZoneConfig(targetFolders: {p('Фото')}),
        overrides: [('Фото/2024', Zone.chaos), ('', Zone.chaos)],
      );
      expectFolders(zones, [('Фото/2024', ZoneReason.templateFolder, 'Фото')]);
    });

    test('a user exclusion can cover a template folder', () {
      final zones = zonesOf(
        config: ZoneConfig(targetFolders: {p('Фото')}),
        overrides: [('Фото', Zone.excluded)],
      );
      expect(zones.zoneOfFolder(p('Фото/2024')), Zone.excluded);
    });

    test('match regardless of case', () {
      final zones = zonesOf(overrides: [('Documents', Zone.excluded)]);
      expect(zones.zoneOfFolder(p('documents/x')), Zone.excluded);
    });

    test('must belong to the source', () {
      expect(
        () => ZoneMap(
          sourceId: testSource,
          overrides: [
            ZoneOverride(
              sourceId: const SourceId('other'),
              folder: p('x'),
              zone: Zone.chaos,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ZoneMap(
          sourceId: testSource,
          files: [fileEntry('a', sourceId: const SourceId('other'))],
        ),
        throwsArgumentError,
      );
    });
  });

  group('skipFolder for the scan', () {
    test('covers exclusions visible from the path', () {
      final zones = zonesOf(
        config: ZoneConfig(appFolders: {p('Organizer')}),
        overrides: [('Private', Zone.excluded), ('Inbox', Zone.chaos)],
      );
      for (final folder in [
        '.cache',
        'Download/node_modules',
        'Android/data',
        'Organizer',
        'Private',
        'Private/deep',
      ]) {
        expect(zones.skipFolder(p(folder)), isTrue, reason: folder);
      }
      for (final folder in ['', 'Download', 'Inbox', 'Documents', 'Telegram']) {
        expect(zones.skipFolder(p(folder)), isFalse, reason: folder);
      }
    });

    test('project folders are only known after the scan', () {
      final zones = zonesOf(files: ['Work/app/pubspec.yaml']);
      expect(zones.skipFolder(p('Work/app')), isFalse);
      expect(zones.zoneOfFolder(p('Work/app')), Zone.excluded);
    });
  });

  group('scenarios', () {
    Future<List<FileEntry>> listAll(InMemoryFileSource fs) async => [
      for (final page in await fs.list().toList())
        ...(page as FileSuccess<FileListPage>).value.entries,
    ];

    Future<Map<String, Zone>> zonesOfFiles(InMemoryFileSource fs) async {
      final files = await listAll(fs);
      final zones = ZoneMap(sourceId: fs.sourceId, files: files);
      return {for (final f in files) f.path.value: zones.zoneOfFile(f.path)};
    }

    test('typical Download folder', () async {
      final zones = await zonesOfFiles(
        InMemoryFileSource()..withTypicalDownloadFolder(),
      );
      expect(zones['Download/invoice_2024.pdf'], Zone.chaos);
      expect(zones['Download/invoice_2024 (1).pdf'], Zone.chaos);
      expect(zones['Download/.cache/thumbs.db'], Zone.excluded);
      expect(
        zones['Download/project/node_modules/left-pad/index.js'],
        Zone.excluded,
      );
      expect(zones['Download/project/main.dart'], Zone.organized);
    });

    test('phone with duplicate photos', () async {
      final zones = await zonesOfFiles(phoneStorage());
      expect(zones['DCIM/Camera/IMG_20230714_093000.jpg'], Zone.organized);
      expect(
        zones['Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images/'
            'IMG-20230715-WA0001.jpg'],
        Zone.chaos,
      );
      expect(
        zones['Telegram/Telegram Images/photo_2024-02-04.jpg'],
        Zone.chaos,
      );
      expect(zones['Download/IMG_20240518_093000 (1).jpg'], Zone.chaos);
      expect(
        zones['Pictures/Screenshots/Screenshot_20240601-101010.png'],
        Zone.organized,
      );
      expect(
        zones['Android/data/com.example.app/cache/blob.bin'],
        Zone.excluded,
      );
    });

    test('organized document archive is never chaos', () async {
      final zones = await zonesOfFiles(
        InMemoryFileSource()..withOrganizedDocumentArchive(),
      );
      expect(zones.values.toSet(), {Zone.organized});
    });
  });

  test('decisions are deterministic and cached', () {
    final a = zonesOf(files: ['Work/app/pubspec.yaml']);
    final b = zonesOf(files: ['Work/app/pubspec.yaml']);
    for (final folder in ['', 'Download', 'Work/app/lib', 'Telegram/x']) {
      expect(a.decideFolder(p(folder)), b.decideFolder(p(folder)));
      expect(a.decideFolder(p(folder)), same(a.decideFolder(p(folder))));
    }
  });
}
