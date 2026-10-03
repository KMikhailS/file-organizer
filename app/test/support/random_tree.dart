import 'dart:math';

import 'fs/in_memory_file_source.dart';

/// A random but reproducible file tree for property tests: chaos,
/// organized, excluded and template folders, names with copy markers and
/// case variants, unknown extensions, duplicates (content from a small
/// pool) and project folders.
InMemoryFileSource randomTree(
  int seed, {
  int files = 40,
  bool caseSensitive = true,
}) {
  final random = Random(seed);
  T pick<T>(List<T> items) => items[random.nextInt(items.length)];

  final fs = InMemoryFileSource(
    caseSensitive: caseSensitive,
    pageSize: 1 + random.nextInt(8),
  );
  const folders = [
    '',
    'Download',
    'Download',
    'Downloads/Telegram Desktop',
    'Desktop',
    'Desktop/New folder',
    'Documents',
    'Documents/Taxes',
    'DCIM/Camera',
    'Telegram/Telegram Images',
    'WhatsApp/Media/WhatsApp Images',
    'Download/.cache',
    'Download/project/node_modules/x',
    'Документы',
    'Фото/2023',
    'Android/data/app',
  ];
  const stems = [
    'report',
    'Report',
    'IMG_0001',
    'photo',
    'song',
    'setup',
    'notes',
    'Screenshot_2024',
    'data',
    'archive',
    'a',
    'b',
  ];
  const extensions = [
    'pdf',
    'PDF',
    'jpg',
    'png',
    'mp3',
    'mp4',
    'exe',
    'txt',
    'zip',
    'tar.gz',
    'xyz',
    '',
    'crdownload',
  ];
  const pool = ['alpha', 'beta', 'gamma', 'delta'];

  if (random.nextBool()) {
    fs.addFile('Desktop/app/pubspec.yaml');
  }
  for (var i = 0; i < files; i++) {
    final folder = pick(folders);
    final ext = pick(extensions);
    final copy = random.nextInt(5) == 0 ? ' (1)' : '';
    final name = '${pick(stems)}$copy${ext.isEmpty ? '' : '.$ext'}';
    final path = folder.isEmpty ? name : '$folder/$name';
    final text = random.nextInt(10) < 4 ? pick(pool) : 'unique-$seed-$i';
    final modified = DateTime.utc(
      2019 + random.nextInt(6),
      1 + random.nextInt(12),
      1 + random.nextInt(28),
    );
    try {
      fs.addFile(
        path,
        text: text,
        modifiedAt: modified,
        capturedAt: random.nextInt(4) == 0
            ? modified.subtract(const Duration(days: 40))
            : null,
      );
    } on StateError {
      // The path is taken (or is a folder): skip it.
    }
  }
  return fs;
}
