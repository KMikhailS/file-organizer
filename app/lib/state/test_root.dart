/// The folder a test build takes as the storage root
/// (`docs/stage2_android.md`, 5.25), or `null` for the real storage.
///
/// [defined] is the `FO_TEST_ROOT` compile-time define. It counts only in
/// a [debug] build: a release build always works on the real storage.
/// Only absolute paths inside the shared storage are accepted.
String? testStorageRoot(String defined, {required bool debug}) {
  if (!debug || defined.isEmpty) {
    return null;
  }
  const storage = '/storage/emulated/0/';
  final root = defined.endsWith('/')
      ? defined.substring(0, defined.length - 1)
      : defined;
  // The storage root itself, even with a slash, is not inside it.
  if (!root.startsWith(storage) ||
      root.split('/').any((s) => s == '..' || s == '.')) {
    throw ArgumentError.value(
      defined,
      'FO_TEST_ROOT',
      'not a folder in $storage',
    );
  }
  return root;
}
