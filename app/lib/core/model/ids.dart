/// Typed identifiers. Extension types keep ids of different entities from
/// being mixed up at compile time without any runtime cost.
library;

/// Identifier of a file source.
extension type const SourceId(String value) {}

/// Identifier of one scan run.
extension type const ScanId(String value) {}

/// Identifier of a cleanup session.
extension type const SessionId(String value) {}

/// Identifier of a journal operation.
extension type const OperationId(String value) {}
