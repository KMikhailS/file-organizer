import 'package:file_organizer/core/layout/layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/model_fixtures.dart';

void main() {
  NameAllocator allocator(Set<String> onDisk) =>
      NameAllocator(taken: onDisk.map(p));

  final docs = p('Документы');

  test('keeps a free name', () {
    expect(allocator({}).claim(docs, 'a.pdf'), p('Документы/a.pdf'));
  });

  test('adds a suffix when the name is taken on disk', () {
    final names = allocator({'Документы/a.pdf', 'Документы/a (2).pdf'});
    expect(names.claim(docs, 'a.pdf'), p('Документы/a (3).pdf'));
  });

  test('names claimed in the same plan are taken too', () {
    final names = allocator({'Документы/a.pdf'});
    expect(names.claim(docs, 'a.pdf'), p('Документы/a (2).pdf'));
    expect(names.claim(docs, 'a.pdf'), p('Документы/a (3).pdf'));
    expect(names.claim(p('Прочее'), 'a.pdf'), p('Прочее/a.pdf'));
  });

  test('compares names regardless of case', () {
    final names = allocator({'Документы/Report.PDF'});
    expect(names.claim(docs, 'report.pdf'), p('Документы/report (2).pdf'));
    expect(
      names.claim(p('документы'), 'REPORT.pdf'),
      p('документы/REPORT (3).pdf'),
    );
  });

  test('handles names without an extension and dotfiles', () {
    final names = allocator({'Прочее/README', 'Прочее/.env'});
    expect(names.claim(p('Прочее'), 'README'), p('Прочее/README (2)'));
    expect(names.claim(p('Прочее'), '.env'), p('Прочее/.env (2)'));
  });

  test('keeps compound extensions together', () {
    final names = allocator({'Архивы/backup.tar.gz'});
    expect(
      names.claim(p('Архивы'), 'backup.tar.gz'),
      p('Архивы/backup (2).tar.gz'),
    );
  });

  test('keeps the original case of the name', () {
    final names = allocator({'Фото/2024/IMG_1.JPG'});
    expect(
      names.claim(p('Фото/2024'), 'IMG_1.JPG'),
      p('Фото/2024/IMG_1 (2).JPG'),
    );
  });

  test('a name with a suffix gets another one', () {
    final names = allocator({'Документы/a (2).pdf'});
    expect(names.claim(docs, 'a (2).pdf'), p('Документы/a (2) (2).pdf'));
  });

  test('gives up on a pathological folder', () {
    final names = allocator({
      'Документы/a.pdf',
      for (var n = 2; n <= NameAllocator.maxSuffix; n++) 'Документы/a ($n).pdf',
    });
    expect(() => names.claim(docs, 'a.pdf'), throwsStateError);
  });
}
