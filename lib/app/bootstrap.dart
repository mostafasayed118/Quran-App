import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> defaultAudioRootResolver() async {
  final dir = await getApplicationSupportDirectory();
  return dir;
}
