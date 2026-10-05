// The A.5 experiment (docs/stage2_android.md, section 4): can the shared
// storage move files without ever replacing a target?
//
// Runs only inside a fresh folder under [runExperiment]'s `root`; never
// touches anything else. Every observation is emitted as one JSON line.
import 'dart:convert';
import 'dart:io';

import 'libc.dart';

/// Receives one JSON-encoded observation.
typedef Emit = void Function(String json);

/// A tiny but valid 8x8 JPEG, so that MediaStore indexes it as an image.
final List<int> jpegBytes = base64.decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9'
  'PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/2wBDARESEhgVGC8aGi9jQjhC'
  'Y2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2P/wAAR'
  'CAAIAAgDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAA'
  'AgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkK'
  'FhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWG'
  'h4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl'
  '5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREA'
  'AgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYk'
  'NOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOE'
  'hYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk'
  '5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwChRRRXmn0R/9k=',
);

/// Runs every check in a new folder under [root].
///
/// [scratch] is a folder on another file system (app-private storage on
/// Android) used for the cross-volume check and the speed baseline.
/// [mediaStore] adds the photo files that the host checks in MediaStore.
/// [files] is the size of the speed test tree.
Future<void> runExperiment({
  required String root,
  required String scratch,
  required Emit emit,
  bool mediaStore = false,
  int files = 5000,
}) async {
  final libc = Libc();
  final base = '$root/run-${DateTime.now().toUtc().millisecondsSinceEpoch}';
  Directory(base).createSync(recursive: true);

  void note(String id, String what, String result, {bool? ok}) =>
      emit(jsonEncode({'id': id, 'what': what, 'result': result, 'ok': ?ok}));

  String? read(String path) =>
      File(path).existsSync() ? File(path).readAsStringSync() : null;
  void write(String path, String content) {
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  List<String> names(String dir) => [
    for (final e in Directory(dir).listSync(followLinks: false))
      e.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
  ]..sort();

  note('ENV', 'platform', Platform.operatingSystemVersion);
  note('ENV', 'mounts', _mounts(root));

  // R1: free target.
  write('$base/r1/a/one.txt', 'one');
  Directory('$base/r1/b').createSync();
  var r = libc.renameat2(
    '$base/r1/a/one.txt',
    '$base/r1/b/one.txt',
    renameNoReplace,
  );
  note(
    'R1',
    'renameat2 NOREPLACE, free target in another folder',
    '${describe(r)}; source exists: ${File('$base/r1/a/one.txt').existsSync()}'
        ', target: ${read('$base/r1/b/one.txt')}',
    ok:
        r.rc == 0 &&
        !File('$base/r1/a/one.txt').existsSync() &&
        read('$base/r1/b/one.txt') == 'one',
  );

  // R2: occupied target file.
  write('$base/r2/src.txt', 'new');
  write('$base/r2/dst.txt', 'old');
  r = libc.renameat2('$base/r2/src.txt', '$base/r2/dst.txt', renameNoReplace);
  note(
    'R2',
    'renameat2 NOREPLACE, target file exists',
    '${describe(r)}; target: ${read('$base/r2/dst.txt')}, '
        'source: ${read('$base/r2/src.txt')}',
    ok:
        r.rc == -1 &&
        r.errno == 17 &&
        read('$base/r2/dst.txt') == 'old' &&
        read('$base/r2/src.txt') == 'new',
  );

  // R3: occupied target folder (plain rename would replace an empty one).
  Directory('$base/r3/d1').createSync(recursive: true);
  write('$base/r3/d1/inside.txt', 'd1');
  Directory('$base/r3/d2').createSync();
  r = libc.renameat2('$base/r3/d1', '$base/r3/d2', renameNoReplace);
  note(
    'R3',
    'renameat2 NOREPLACE, target is an existing empty folder',
    '${describe(r)}; entries: ${names('$base/r3')}',
    ok: r.rc == -1 && r.errno == 17 && read('$base/r3/d1/inside.txt') == 'd1',
  );

  // R3b: folder to a free target.
  r = libc.renameat2('$base/r3/d1', '$base/r3/d3', renameNoReplace);
  note(
    'R3b',
    'renameat2 NOREPLACE, folder to a free name',
    '${describe(r)}; entries: ${names('$base/r3')}',
    ok: r.rc == 0 && read('$base/r3/d3/inside.txt') == 'd1',
  );

  // R4: target differs from an existing file only by case.
  write('$base/r4/b.txt', 'old');
  write('$base/r4/a.txt', 'new');
  r = libc.renameat2('$base/r4/a.txt', '$base/r4/B.TXT', renameNoReplace);
  note(
    'R4',
    'renameat2 NOREPLACE a.txt -> B.TXT while b.txt exists',
    '${describe(r)}; entries: ${names('$base/r4')}, '
        'b.txt: ${read('$base/r4/b.txt')}',
    ok: read('$base/r4/b.txt') == 'old',
  );

  // R5: case-only rename of the same file.
  write('$base/r5/photo.jpg', 'p');
  r = libc.renameat2(
    '$base/r5/photo.jpg',
    '$base/r5/Photo.JPG',
    renameNoReplace,
  );
  note(
    'R5',
    'renameat2 NOREPLACE photo.jpg -> Photo.JPG (same file, case only)',
    '${describe(r)}; entries: ${names('$base/r5')}',
  );

  // R6: target folder does not exist.
  write('$base/r6/src.txt', 's');
  r = libc.renameat2(
    '$base/r6/src.txt',
    '$base/r6/missing/src.txt',
    renameNoReplace,
  );
  note(
    'R6',
    'renameat2 NOREPLACE into a missing folder',
    describe(r),
    ok: r.rc == -1 && r.errno == 2 && read('$base/r6/src.txt') == 's',
  );

  // R7: source does not exist.
  r = libc.renameat2('$base/r6/nope.txt', '$base/r6/x.txt', renameNoReplace);
  note(
    'R7',
    'renameat2 NOREPLACE, missing source',
    describe(r),
    ok: r.rc == -1 && r.errno == 2,
  );

  // R8: another volume.
  write('$base/r8/src.txt', 'v');
  final crossTarget = '$scratch/a5-cross-${DateTime.now().microsecond}.txt';
  r = libc.renameat2('$base/r8/src.txt', crossTarget, renameNoReplace);
  note(
    'R8',
    'renameat2 NOREPLACE to another volume ($scratch)',
    '${describe(r)}; source: ${read('$base/r8/src.txt')}',
  );
  if (File(crossTarget).existsSync()) {
    File(crossTarget).deleteSync();
  }

  // R9: control. dart:io File.rename replaces the target.
  write('$base/r9/src.txt', 'new');
  write('$base/r9/dst.txt', 'old');
  File('$base/r9/src.txt').renameSync('$base/r9/dst.txt');
  note(
    'R9',
    'control: dart:io File.renameSync onto an existing file',
    'target now: ${read('$base/r9/dst.txt')}',
  );

  // L1: hard link.
  write('$base/l1/src.txt', 'l');
  r = libc.link('$base/l1/src.txt', '$base/l1/dst.txt');
  note(
    'L1',
    'link(src, free target)',
    '${describe(r)}; entries: ${names('$base/l1')}',
  );
  write('$base/l1/occupied.txt', 'o');
  r = libc.link('$base/l1/src.txt', '$base/l1/occupied.txt');
  note(
    'L1b',
    'link(src, existing target)',
    '${describe(r)}; occupied: ${read('$base/l1/occupied.txt')}',
  );

  // L2: symbolic link.
  try {
    Link('$base/l2/link').createSync('$base/l1/src.txt', recursive: true);
    note('L2', 'symlink in shared storage', 'created');
  } on FileSystemException catch (e) {
    note('L2', 'symlink in shared storage', 'failed: ${e.osError}');
  }

  // M1-M4: mkdir.
  Directory('$base/m').createSync();
  var m = libc.mkdir('$base/m/new');
  note('M1', 'mkdir, new folder', describe(m), ok: m.rc == 0);
  m = libc.mkdir('$base/m/new');
  note(
    'M2',
    'mkdir, folder exists',
    describe(m),
    ok: m.rc == -1 && m.errno == 17,
  );
  m = libc.mkdir('$base/m/NEW');
  note(
    'M3',
    'mkdir NEW while new exists',
    '${describe(m)}; entries: ${names('$base/m')}',
  );
  write('$base/m/file', 'f');
  m = libc.mkdir('$base/m/file');
  note(
    'M4',
    'mkdir over an existing file',
    describe(m),
    ok: m.rc == -1 && m.errno == 17 && read('$base/m/file') == 'f',
  );

  // D1-D2: rmdir.
  write('$base/d/full/x.txt', 'x');
  var d = libc.rmdir('$base/d/full');
  note(
    'D1',
    'rmdir, folder not empty',
    describe(d),
    ok: d.rc == -1 && d.errno == 39 && read('$base/d/full/x.txt') == 'x',
  );
  Directory('$base/d/empty').createSync();
  d = libc.rmdir('$base/d/empty');
  note('D2', 'rmdir, empty folder', describe(d), ok: d.rc == 0);

  // C1: case sensitivity.
  write('$base/c/Case.txt', 'c');
  note(
    'C1',
    'Case.txt exists; lookups by other case',
    'case.txt: ${File('$base/c/case.txt').existsSync()}, '
        'CASE.TXT: ${File('$base/c/CASE.TXT').existsSync()}, '
        'listing: ${names('$base/c')}',
  );
  Directory('$base/c/Folder').createSync();
  note(
    'C2',
    'Folder exists; lookup folder',
    'folder: ${Directory('$base/c/folder').existsSync()}',
  );

  // X1-X2: reserve the target name with O_CREAT | O_EXCL, then rename onto
  // the own empty placeholder (fallback candidate where NOREPLACE is EINVAL).
  write('$base/x/taken.txt', 'old');
  note(
    'X1',
    'create(exclusive) on a free name / on an existing name',
    '${_exclusive('$base/x/free.txt')} / ${_exclusive('$base/x/taken.txt')}'
        '; taken.txt: ${read('$base/x/taken.txt')}',
    ok: read('$base/x/taken.txt') == 'old',
  );
  write('$base/x/src/doc.pdf', 'pdf');
  Directory('$base/x/dst').createSync();
  final reserved = _exclusive('$base/x/dst/doc.pdf');
  File('$base/x/src/doc.pdf').renameSync('$base/x/dst/doc.pdf');
  note(
    'X2',
    'reserve dst/doc.pdf exclusively, then rename src onto the placeholder',
    'reserve: $reserved; source exists: '
        '${File('$base/x/src/doc.pdf').existsSync()}, '
        'target: ${read('$base/x/dst/doc.pdf')}',
    ok:
        reserved == 'ok' &&
        !File('$base/x/src/doc.pdf').existsSync() &&
        read('$base/x/dst/doc.pdf') == 'pdf',
  );

  // MS: photos for the MediaStore check. The host indexes them
  // (scan_volume), creates ms/go, and queries MediaStore after the move.
  if (mediaStore) {
    for (final path in ['keep/a.jpg', 'src/b.jpg', 'src/c.jpg']) {
      File('$base/ms/$path')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(jpegBytes);
    }
    Directory('$base/ms/dst').createSync();
    emit(jsonEncode({'id': 'MS_READY', 'what': 'photos', 'result': base}));
    final go = File('$base/ms/go');
    for (var i = 0; i < 180 && !go.existsSync(); i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    r = libc.renameat2(
      '$base/ms/src/b.jpg',
      '$base/ms/dst/b.jpg',
      renameNoReplace,
    );
    note(
      'MS',
      'indexed photo src/b.jpg -> dst/b.jpg with renameat2 NOREPLACE',
      describe(r),
    );
    final reservedPhoto = _exclusive('$base/ms/dst/c.jpg');
    File('$base/ms/src/c.jpg').renameSync('$base/ms/dst/c.jpg');
    note(
      'MSb',
      'indexed photo src/c.jpg -> dst/c.jpg with reserve + rename',
      'reserve: $reservedPhoto',
    );
    emit(jsonEncode({'id': 'MS_MOVED', 'what': 'photos', 'result': base}));
  }

  // P: speed of create / list / stat, shared storage vs [scratch].
  for (final (label, dir) in [
    ('storage', '$base/p'),
    ('app-private', '$scratch/a5-speed-${DateTime.now().microsecond}'),
  ]) {
    note(
      'P',
      '$files files in ${files ~/ 100} folders, $label',
      _speed(dir, files),
    );
    if (label == 'app-private') {
      Directory(dir).deleteSync(recursive: true);
    }
  }

  emit(jsonEncode({'id': 'BASE', 'what': 'run folder', 'result': base}));
}

/// Creates [path] only if nothing exists there (`O_CREAT | O_EXCL`).
String _exclusive(String path) {
  try {
    File(path).createSync(exclusive: true);
    return 'ok';
  } on FileSystemException catch (e) {
    return 'failed: ${e.osError?.message} (${e.osError?.errorCode})';
  }
}

String _speed(String dir, int files) {
  final watch = Stopwatch()..start();
  for (var f = 0; f < files ~/ 100; f++) {
    final folder = Directory('$dir/f$f')..createSync(recursive: true);
    for (var i = 0; i < 100; i++) {
      File('${folder.path}/file$i.bin').writeAsBytesSync(const [1, 2, 3]);
    }
  }
  final create = watch.elapsedMilliseconds;

  watch.reset();
  final found = <String>[];
  final pending = [dir];
  while (pending.isNotEmpty) {
    final current = pending.removeLast();
    for (final entry in Directory(current).listSync(followLinks: false)) {
      if (entry is Directory) {
        pending.add(entry.path);
      } else {
        found.add(entry.path);
      }
    }
  }
  final list = watch.elapsedMilliseconds;

  watch.reset();
  var bytes = 0;
  for (final path in found) {
    bytes += File(path).statSync().size;
  }
  final stat = watch.elapsedMilliseconds;

  return 'create ${create}ms, list ${list}ms (${found.length} files), '
      'stat ${stat}ms ($bytes bytes)';
}

String _mounts(String root) {
  try {
    final lines = File('/proc/self/mounts').readAsLinesSync();
    final relevant = lines.where(
      (l) =>
          l.contains('/storage/emulated') ||
          (Platform.isLinux && !Platform.isAndroid && l.contains(' / ')),
    );
    return relevant.take(3).join(' | ');
  } on FileSystemException catch (e) {
    return 'unreadable: ${e.osError}';
  }
}
