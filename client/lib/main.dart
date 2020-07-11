import 'package:client/locator.dart';
import 'package:client/src/meta_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import 'ui/exolutio.dart';
import 'ui/view_model.dart';

void main() async {
  if (kDebugMode) {
    Wakelock.enable();
  }

  await setUp();

  runApp(
    MultiProvider(
      providers: [
        // TODO move to home?
        provide<HtmlViewModel>(),
        provide<MetaModel>(),
      ],
      child: Selector<MetaModel, String>(
        selector: (_, model) => model.font,
        builder: (_, font, __) => Exolutio(font),
      ),
    ),
  );
}

ChangeNotifierProvider<T> provide<T extends ChangeNotifier>() {
  return ChangeNotifierProvider<T>(create: (_) => locator<T>());
}
