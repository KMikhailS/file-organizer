/// Category of a file. Each category except [unresolved] maps to a folder of
/// the layout template.
enum Category {
  documents,
  photos,
  videos,
  screenshots,
  music,
  archives,
  installers,
  other,

  /// The rules are not sure. Without AI such files stay where they are and
  /// are shown in the plan as "Unresolved".
  unresolved,
}
