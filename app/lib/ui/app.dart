import 'package:file_organizer/ui/placeholder_screen.dart';
import 'package:flutter/material.dart';

/// The app shell.
class FileOrganizerApp extends StatelessWidget {
  const FileOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'File Organizer',
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: const PlaceholderScreen(),
  );
}
