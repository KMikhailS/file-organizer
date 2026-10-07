import 'package:file_organizer/core/model/file_error_kind.dart';
import 'package:file_organizer/platform/posix/errno_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileErrorKindOf', () {
    // docs/stage2_android.md, section 5.1; numbers from <errno.h>.
    const common = <int, FileErrorKind>{
      2: FileErrorKind.notFound, // ENOENT
      20: FileErrorKind.wrongType, // ENOTDIR
      21: FileErrorKind.wrongType, // EISDIR
      13: FileErrorKind.permissionDenied, // EACCES
      1: FileErrorKind.permissionDenied, // EPERM
      30: FileErrorKind.permissionDenied, // EROFS
      17: FileErrorKind.targetExists, // EEXIST
      18: FileErrorKind.ioError, // EXDEV: another volume
      16: FileErrorKind.locked, // EBUSY
      26: FileErrorKind.locked, // ETXTBSY
      5: FileErrorKind.ioError, // EIO
      28: FileErrorKind.ioError, // ENOSPC
      0: FileErrorKind.ioError,
      -1: FileErrorKind.ioError,
    };

    for (final flavor in PosixFlavor.values) {
      test('maps the common numbers on ${flavor.name}', () {
        for (final MapEntry(key: errno, value: kind) in common.entries) {
          expect(fileErrorKindOf(errno, flavor), kind, reason: 'errno $errno');
        }
      });
    }

    test('ENOTEMPTY differs between Linux and macOS', () {
      expect(fileErrorKindOf(39, PosixFlavor.linux), FileErrorKind.notEmpty);
      expect(fileErrorKindOf(66, PosixFlavor.darwin), FileErrorKind.notEmpty);
      // 39 is EDESTADDRREQ on macOS; 66 is EREMOTE on Linux.
      expect(fileErrorKindOf(39, PosixFlavor.darwin), FileErrorKind.ioError);
      expect(fileErrorKindOf(66, PosixFlavor.linux), FileErrorKind.ioError);
    });
  });
}
