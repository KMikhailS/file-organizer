import 'package:file_organizer/state/app_services.dart';
import 'package:file_organizer/state/providers.dart';
import 'package:file_organizer/state/test_root.dart';
import 'package:file_organizer/ui/app.dart';
import 'package:file_organizer/ui/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A folder that stands for the storage root in a test build:
/// `--dart-define=FO_TEST_ROOT=/storage/emulated/0/FileOrganizerTest`.
const String _testRoot = String.fromEnvironment('FO_TEST_ROOT');

void main() {
  final testRoot = testStorageRoot(_testRoot, debug: kDebugMode);
  runApp(
    ProviderScope(
      overrides: [
        appServicesProvider.overrideWithValue(
          AppServices.android(testRoot: testRoot),
        ),
        ...localizationOverrides(),
      ],
      child: const FileOrganizerApp(),
    ),
  );
}
