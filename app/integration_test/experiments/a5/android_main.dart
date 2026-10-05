// Entry point of the A.5 experiment on Android. Built and started by
// run_android.sh, which grants "All files access" before the start and
// reads the results from logcat.
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'a5_checks.dart';

/// Shared storage folder used only by the experiment.
const String experimentRoot = '/storage/emulated/0/FileOrganizerTest';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const Center(
      child: Text('A.5 experiment', textDirection: TextDirection.ltr),
    ),
  );
  try {
    await runExperiment(
      root: experimentRoot,
      scratch: Directory.systemTemp.path,
      mediaStore: true,
      emit: (json) => debugPrint('A5|$json'),
    );
  } on Object catch (e, stack) {
    debugPrint('A5|{"id":"FAIL","what":"exception","result":"$e"}');
    debugPrint('$stack');
  }
  debugPrint('A5|DONE');
}
