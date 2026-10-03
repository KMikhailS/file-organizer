import 'package:flutter/material.dart';

void main() {
  runApp(const FileOrganizerApp());
}

/// Empty application shell. Screens are added in stage 2.
class FileOrganizerApp extends StatelessWidget {
  const FileOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'File Organizer', home: Scaffold());
  }
}
