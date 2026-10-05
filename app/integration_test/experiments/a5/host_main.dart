// The A.5 experiment on the Linux host (control column):
// `dart run integration_test/experiments/a5/host_main.dart` from app/.
import 'dart:io';

import 'a5_checks.dart';

Future<void> main() async {
  final root = Directory.systemTemp.createTempSync('a5-root-');
  final scratch = Directory.systemTemp.createTempSync('a5-scratch-');
  try {
    await runExperiment(
      root: root.path,
      scratch: scratch.path,
      emit: stdout.writeln,
    );
  } finally {
    root.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
  }
}
