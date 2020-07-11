import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

import 'locator.dart';
import 'ui/exolutio.dart';

void main() async {
  if (kDebugMode) Wakelock.enable();

  await setUp();

  runApp(Exolutio());
}
