import 'package:client/src/firebase.dart';
import 'package:client/src/loader.dart';
import 'package:client/src/meta_model.dart';
import 'package:client/ui/exolutio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

import 'ui/view_model.dart';

GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Wakelock.enable();
  }

  final prefs = await SharedPreferences.getInstance();

  locator.registerSingleton(HtmlViewModel(Loader()));
  locator.registerSingleton(MetaModel(prefs));
  locator.registerSingleton(Firebase());

  runApp(
    MultiProvider(
      providers: [
        // TODO move to home?
        provide<HtmlViewModel>(),
        provide<MetaModel>(),
      ],
      child: Exolutio(),
    ),
  );
}

ChangeNotifierProvider<T> provide<T extends ChangeNotifier>() {
  return ChangeNotifierProvider<T>(create: (_) => locator<T>());
}
