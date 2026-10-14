import 'dart:io' as io;

/// The size of a regular file, read past a stale size of the file system
/// (`docs/stage2_android.md`, 5.26).
///
/// On an Android 13 phone (MagicOS) the FUSE layer of the shared storage
/// kept reporting size 0 through `stat`, `fstat` and `lseek` for minutes
/// after a process had written a file, while reading gave the content
/// (2.5–7 % of freshly written files; only 0, never another wrong size).
/// A size taken from such a report made the undo refuse those files as
/// "changed". So a regular file reported empty is counted by reading it:
/// a really empty file costs one open.
class SizeReader {
  const SizeReader();

  /// The size of the regular file at [real], for which the system reported
  /// [reported] bytes. If the file cannot be read, [reported].
  Future<int> size(String real, int reported) async {
    if (reported != 0) {
      return reported;
    }
    try {
      return await io.File(real)
          .openRead()
          .fold<int>(0, (total, chunk) => total + chunk.length);
    } on io.FileSystemException {
      return reported;
    }
  }
}
