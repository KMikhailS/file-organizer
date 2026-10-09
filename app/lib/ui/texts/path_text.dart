import 'package:file_organizer/core/model/logical_path.dart';

/// How a path inside a source is shown: relative to the source root, which
/// itself is `/`.
String pathText(LogicalPath path) => path.isRoot ? '/' : path.value;
