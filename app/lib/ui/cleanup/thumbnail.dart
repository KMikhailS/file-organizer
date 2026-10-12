import 'package:file_organizer/core/model/operation_type.dart';
import 'package:file_organizer/core/model/source.dart';
import 'package:file_organizer/state/cleanup/cleanup_providers.dart';
import 'package:file_organizer/state/cleanup/cleanup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The thumbnail of a photo or video of the plan (from the system), or an
/// icon for other files and while it loads.
class Thumbnail extends ConsumerWidget {
  const Thumbnail({required this.source, required this.file, super.key});

  static const double size = 48;

  final Source source;
  final OperationView file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = Icon(
      file.type == OperationType.quarantine
          ? Icons.content_copy_outlined
          : Icons.insert_drive_file_outlined,
    );
    if (!file.media) {
      return SizedBox.square(dimension: size, child: icon);
    }
    final bytes = ref.watch(thumbnailProvider((source, file.from))).value;
    return SizedBox.square(
      dimension: size,
      child: bytes == null
          ? icon
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                bytes,
                key: const ValueKey('thumbnail'),
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => icon,
              ),
            ),
    );
  }
}
