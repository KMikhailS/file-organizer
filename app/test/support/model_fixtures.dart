import 'package:file_organizer/core/model/model.dart';

/// Default source of fixtures.
const SourceId testSource = SourceId('test-source');

/// A fixed point in time for fixtures, in UTC.
final DateTime testTime = DateTime.utc(2024, 5, 17, 10, 30);

/// A logical path.
LogicalPath p(String value) => LogicalPath(value);

/// A file entry with sensible defaults.
FileEntry fileEntry(
  String path, {
  SourceId sourceId = testSource,
  int size = 1024,
  DateTime? modifiedAt,
  DateTime? capturedAt,
  String? mimeType,
  String? partialHash,
  String? fullHash,
  ScanId? lastSeenScanId,
}) => FileEntry(
  sourceId: sourceId,
  path: LogicalPath(path),
  size: size,
  modifiedAt: modifiedAt ?? testTime,
  capturedAt: capturedAt,
  mimeType: mimeType,
  partialHash: partialHash,
  fullHash: fullHash,
  lastSeenScanId: lastSeenScanId,
);

/// A fingerprint with sensible defaults.
Fingerprint fingerprint({
  int size = 1024,
  DateTime? modifiedAt,
  String? hash,
}) =>
    Fingerprint(size: size, modifiedAt: modifiedAt ?? testTime, fullHash: hash);

/// A planned move with sensible defaults.
PlannedOperation plannedMove(
  String from,
  String to, {
  String groupKey = 'move',
  bool approved = true,
  int size = 1024,
}) => PlannedOperation.move(
  sourceId: testSource,
  from: LogicalPath(from),
  to: LogicalPath(to),
  fingerprint: fingerprint(size: size),
  reason: 'test move',
  groupKey: groupKey,
  approved: approved,
);

/// A planned quarantine with sensible defaults.
PlannedOperation plannedQuarantine(
  String path, {
  String groupKey = 'duplicates',
  bool approved = true,
  int size = 1024,
}) => PlannedOperation.quarantine(
  sourceId: testSource,
  path: LogicalPath(path),
  fingerprint: fingerprint(size: size),
  reason: 'test quarantine',
  groupKey: groupKey,
  approved: approved,
);

/// A planned mkdir with sensible defaults.
PlannedOperation plannedMkdir(
  String path, {
  String groupKey = 'move',
  bool approved = true,
}) => PlannedOperation.mkdir(
  sourceId: testSource,
  path: LogicalPath(path),
  reason: 'test mkdir',
  groupKey: groupKey,
  approved: approved,
);
