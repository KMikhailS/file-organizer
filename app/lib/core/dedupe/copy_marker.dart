/// Whether a file name looks like a copy of another file: `photo (1).jpg`,
/// `photo(2).jpg`, `report - Copy.docx`, `report - Copy (2).docx`,
/// `report copy 2.txt`, `Copy of report.txt`, `отчёт — копия.docx`.
///
/// Only used to prefer the original when choosing which duplicate to keep;
/// a false match never causes any action by itself.
bool hasCopyMarker(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
  return _copyMarkers.any((marker) => marker.hasMatch(stem));
}

const String _copyWords = 'copy|копия|kopie|copie|copia|cópia|kopya';

final List<RegExp> _copyMarkers = [
  // "name (1)", "name(2)".
  RegExp(r'\(\d+\)$'),
  // "name - Copy", "name copy", "name_copy 2", "name — копия (3)".
  RegExp('[\\s_\\-–—]($_copyWords)(\\s*\\(?\\d+\\)?)?\$', caseSensitive: false),
  // "Copy of name", "Копия name".
  RegExp('^($_copyWords)(\\s+of)?\\s', caseSensitive: false),
];
