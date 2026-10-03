/// Source of unique identifiers. The core never generates ids itself.
abstract interface class IdGenerator {
  /// A new identifier, unique within the app's data.
  String newId();
}
