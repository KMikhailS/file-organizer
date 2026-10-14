import 'package:file_organizer/platform/android/native_api.g.dart';

/// The shared storage as seen by a test build (`docs/stage2_android.md`,
/// 5.25): the folder [root] stands for the storage root, so a cleanup on a
/// real device never reaches the owner's files. Everything else (capture
/// dates, thumbnails) still comes from the system.
final class TestRootStorage extends StorageApi {
  TestRootStorage(this.root);

  /// An absolute path inside the shared storage, such as
  /// `/storage/emulated/0/FileOrganizerTest`.
  final String root;

  @override
  Future<String?> primaryStorageRoot() async => root;
}
