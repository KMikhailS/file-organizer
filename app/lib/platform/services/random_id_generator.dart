import 'dart:math';

import 'package:file_organizer/core/ports/id_generator.dart';

/// The real [IdGenerator]: random UUIDs, version 4 (RFC 9562), in lower
/// case: `xxxxxxxx-xxxx-4xxx-Nxxx-xxxxxxxxxxxx` where `N` is 8, 9, a or b.
///
/// 122 random bits from [Random.secure] make a collision practically
/// impossible, so ids stay unique across sessions, sources and app restarts.
final class RandomIdGenerator implements IdGenerator {
  /// [random] is for tests only; by default the cryptographically secure
  /// generator of the platform.
  RandomIdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    // Version 4 in the high nibble of byte 6, variant 10xx in byte 8.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10).join()}';
  }
}
