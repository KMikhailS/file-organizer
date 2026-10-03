import 'package:file_organizer/core/model/logical_path.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/value_equality.dart';

void main() {
  group('validation', () {
    const valid = [
      '',
      'a',
      'Download/scan.pdf',
      'Фото/2024/IMG_0001.HEIC',
      '.hidden/file',
      '..file',
      'a..b/c...d',
      'with space/and (1).txt',
      r'back\slash',
    ];
    for (final value in valid) {
      test('accepts "$value"', () {
        expect(LogicalPath.problemWith(value), isNull);
        expect(LogicalPath(value).value, value);
      });
    }

    const invalid = {
      'leading slash': '/etc/passwd',
      'trailing slash': 'Download/',
      'only slash': '/',
      'empty segment': 'a//b',
      'dot': '.',
      'dot segment': 'a/./b',
      'dot-dot': '..',
      'dot-dot segment': 'Download/../../etc',
      'dot-dot at end': 'a/..',
      'NUL': 'a\u0000b',
    };
    for (final MapEntry(key: name, value: value) in invalid.entries) {
      test('rejects $name', () {
        expect(LogicalPath.problemWith(value), isNotNull);
        expect(() => LogicalPath(value), throwsArgumentError);
      });
    }
  });

  group('root', () {
    test('is the empty path', () {
      expect(LogicalPath.root.isRoot, isTrue);
      expect(LogicalPath(''), LogicalPath.root);
      expect(LogicalPath.root.segments, isEmpty);
      expect(LogicalPath.root.name, '');
      expect(LogicalPath.root.parent, isNull);
    });
  });

  group('parts', () {
    test('segments, name and parent', () {
      final path = LogicalPath('Download/docs/scan.pdf');
      expect(path.segments, ['Download', 'docs', 'scan.pdf']);
      expect(path.name, 'scan.pdf');
      expect(path.parent, LogicalPath('Download/docs'));
      expect(path.parent!.parent, LogicalPath('Download'));
      expect(path.parent!.parent!.parent, LogicalPath.root);
    });

    test('segments are unmodifiable', () {
      expect(
        () => LogicalPath('a/b').segments.add('c'),
        throwsUnsupportedError,
      );
    });

    const extensions = {
      'scan.pdf': ('pdf', 'scan'),
      'Photo.JPG': ('jpg', 'Photo'),
      'archive.tar.gz': ('gz', 'archive.tar'),
      '.bashrc': ('', '.bashrc'),
      '.config.json': ('json', '.config'),
      'README': ('', 'README'),
      'file.': ('', 'file.'),
      'dir/name with.dots.txt': ('txt', 'name with.dots'),
    };
    for (final MapEntry(key: value, value: (ext, stem)) in extensions.entries) {
      test('extension and stem of "$value"', () {
        final path = LogicalPath(value);
        expect(path.extension, ext);
        expect(path.stem, stem);
      });
    }
  });

  group('composition', () {
    test('join', () {
      expect(
        LogicalPath('a/b').join(LogicalPath('c/d')),
        LogicalPath('a/b/c/d'),
      );
      expect(LogicalPath.root.join(LogicalPath('c')), LogicalPath('c'));
      expect(LogicalPath('a').join(LogicalPath.root), LogicalPath('a'));
    });

    test('child', () {
      expect(LogicalPath('a').child('b.txt'), LogicalPath('a/b.txt'));
      expect(LogicalPath.root.child('b'), LogicalPath('b'));
    });

    for (final bad in ['', 'x/y', '..', '.']) {
      test('child rejects "$bad"', () {
        expect(() => LogicalPath('a').child(bad), throwsArgumentError);
      });
    }

    test('isWithin and isSameOrWithin', () {
      final download = LogicalPath('Download');
      expect(LogicalPath('Download/a.pdf').isWithin(download), isTrue);
      expect(LogicalPath('Download/x/a.pdf').isWithin(download), isTrue);
      expect(download.isWithin(download), isFalse);
      expect(download.isSameOrWithin(download), isTrue);
      expect(LogicalPath('Downloads/a.pdf').isWithin(download), isFalse);
      expect(LogicalPath('a').isWithin(LogicalPath.root), isTrue);
      expect(LogicalPath.root.isWithin(LogicalPath.root), isFalse);
      expect(LogicalPath.root.isWithin(download), isFalse);
    });
  });

  group('equality and order', () {
    test('value equality', () {
      expectValueEquality(() => LogicalPath('Download/a.pdf'), {
        'value': LogicalPath('Download/b.pdf'),
        'case': LogicalPath('download/a.pdf'),
      });
    });

    test('orders by code units, independent of locale', () {
      final paths = [
        LogicalPath('b'),
        LogicalPath('a/b'),
        LogicalPath('B'),
        LogicalPath('a'),
        LogicalPath.root,
      ]..sort();
      expect(paths.map((p) => p.value), ['', 'B', 'a', 'a/b', 'b']);
    });

    test('toString is the value', () {
      expect(LogicalPath('a/b').toString(), 'a/b');
    });
  });
}
