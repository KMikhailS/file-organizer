import 'package:file_organizer/core/model/ids.dart';
import 'package:file_organizer/platform/posix/no_replace_mover.dart';
import 'package:file_organizer/platform/posix/posix_file_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_clock.dart';

/// Opens the POSIX adapter on [root] (a temporary folder of the test) and
/// disposes it after the test.
Future<PosixFileSource> openPosix(
  String root, {
  int pageSize = PosixFileSource.defaultPageSize,
  int hashBlockSize = 1024 * 1024,
  MoveMechanism? mechanism,
  FakeClock? clock,
}) async {
  final source = await PosixFileSource.open(
    sourceId: const SourceId('posix'),
    root: root,
    clock: clock ?? FakeClock(start: DateTime.utc(2024, 6, 2)),
    pageSize: pageSize,
    hashBlockSize: hashBlockSize,
    forceMechanism: mechanism,
  );
  addTearDown(source.dispose);
  return source;
}
