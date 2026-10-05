/// Why a file operation failed.
///
/// Part of the model (not only of the ports) because journal records keep
/// it (`FileSystemError`) and the UI turns it into text.
enum FileErrorKind {
  /// The path (or the quarantine object) does not exist.
  notFound,

  /// Something already exists at the target. Nothing is ever overwritten.
  targetExists,

  /// The OS or the user did not grant access.
  permissionDenied,

  /// The file is in use by another process.
  locked,

  /// The source cannot do this (see its capabilities).
  unsupported,

  /// A folder to remove is not empty.
  notEmpty,

  /// A file was expected but the path is a folder, or the other way round.
  wrongType,

  /// The caller cancelled the call (`CancelToken`); nothing changed.
  cancelled,

  /// Any other I/O failure.
  ioError,
}
