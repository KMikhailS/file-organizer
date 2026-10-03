/// Role of a folder in a cleanup.
enum Zone {
  /// Clean up: files here are classified and moved.
  chaos,

  /// Organized by the user: never modified.
  organized,

  /// Never modified and never scanned.
  excluded,

  /// Folders of the layout template that files are moved into.
  target,
}
