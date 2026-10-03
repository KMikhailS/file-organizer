import 'dart:convert';

/// Size of each end of a file covered by the partial hash.
const int partialHashChunk = 64 * 1024;

/// FNV-1a (64 bit) of [bytes] as 16 hex digits. Fast and deterministic;
/// good enough for a fake file system.
String fnv1a64(Iterable<int> bytes) {
  // FNV offset basis; hex literals wrap to 64-bit two's complement.
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final byte in bytes) {
    hash ^= byte & 0xff;
    hash *= prime;
  }
  // Two unsigned 32-bit halves: a 64-bit int may be negative in Dart.
  final high = (hash >>> 32).toRadixString(16).padLeft(8, '0');
  final low = (hash & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return '$high$low';
}

/// Hash of the whole content.
String fakeFullHash(List<int> content) => 'f:${fnv1a64(content)}';

/// Hash of the size and the first and last 64 KB.
String fakePartialHash(List<int> content) {
  final head = content.length <= partialHashChunk
      ? content
      : content.sublist(0, partialHashChunk);
  final tail = content.length <= partialHashChunk
      ? const <int>[]
      : content.sublist(content.length - partialHashChunk);
  return 'p:${fnv1a64([...utf8.encode('${content.length}:'), ...head, ...tail])}';
}
