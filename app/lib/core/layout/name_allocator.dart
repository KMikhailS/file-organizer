import 'package:file_organizer/core/model/logical_path.dart';

/// Picks free file names for the operations of one plan.
///
/// A name is taken if something is there now (`taken`: the files and
/// folders of the source) or another operation of the plan already claimed
/// it. A taken name gets a suffix:
/// `name (2).ext`, `name (3).ext`, ... Names are compared
/// case-insensitively on every file system: `A.jpg` and `a.jpg` are the same
/// name on Windows and Android, and a spare suffix is harmless elsewhere.
///
/// Best effort only: the file source never overwrites anyway.
final class NameAllocator {
  NameAllocator({Iterable<LogicalPath> taken = const []})
    : _taken = {for (final path in taken) path.value.toLowerCase()};

  /// Extensions made of two parts, kept together: `archive (2).tar.gz`.
  static const Set<String> compoundExtensions = {'tar.gz', 'tar.bz2', 'tar.xz'};

  /// Gives up after this many suffixes (a bug or a pathological folder).
  static const int maxSuffix = 10000;

  final Set<String> _taken;

  /// Claims a free path for a file named [name] in [folder].
  LogicalPath claim(LogicalPath folder, String name) {
    final (stem, extension) = split(name);
    for (var n = 1; n <= maxSuffix; n++) {
      final candidate = folder.child(
        n == 1 ? name : '$stem ($n)${extension.isEmpty ? '' : '.$extension'}',
      );
      if (_taken.add(candidate.value.toLowerCase())) {
        return candidate;
      }
    }
    throw StateError('No free name for $name in $folder');
  }

  /// Splits [name] into stem and extension (without the dot), keeping
  /// compound extensions whole: `archive.tar.gz` → (`archive`, `tar.gz`).
  /// A leading dot does not start an extension.
  static (String, String) split(String name) {
    final lower = name.toLowerCase();
    for (final compound in compoundExtensions) {
      if (lower.endsWith('.$compound') && lower.length > compound.length + 1) {
        final cut = name.length - compound.length - 1;
        return (name.substring(0, cut), name.substring(cut + 1));
      }
    }
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return (name, '');
    }
    return (name.substring(0, dot), name.substring(dot + 1));
  }
}
