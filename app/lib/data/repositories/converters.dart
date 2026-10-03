/// Conversions shared by the drift repositories.
library;

/// Microseconds since the epoch, UTC: exact, unlike drift's default seconds.
int toMicros(DateTime time) => time.toUtc().microsecondsSinceEpoch;

DateTime fromMicros(int micros) =>
    DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);

DateTime? fromMicrosOrNull(int? micros) =>
    micros == null ? null : fromMicros(micros);

/// SQLite has a limit on query parameters; long `IN` lists go in chunks.
const int maxParametersPerQuery = 500;

Iterable<List<T>> chunked<T>(
  List<T> items, [
  int size = maxParametersPerQuery,
]) sync* {
  for (var i = 0; i < items.length; i += size) {
    yield items.sublist(i, i + size > items.length ? items.length : i + size);
  }
}
