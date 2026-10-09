import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/core/ports/file_source.dart';

/// The file sources that are open now, by id. `CleanupWorkflow` asks for a
/// source synchronously, but opening one is asynchronous (the capability
/// probe), so sources are opened ahead and looked up here.
final class OpenSources {
  final Map<SourceId, FileSource> _open = {};

  /// The open source [id], or `null` if it is not open (no access, not
  /// mounted).
  FileSource? lookup(SourceId id) => _open[id];

  void put(FileSource source) => _open[source.sourceId] = source;

  void remove(SourceId id) => _open.remove(id);
}
