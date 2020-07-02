import 'package:exolutio/src/firebase.dart';
import 'package:exolutio/src/loader.dart';
import 'package:exolutio/src/model.dart';
import 'package:exolutio/ui/exolutio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

GetIt locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Wakelock.enable();
  }

  final prefs = await SharedPreferences.getInstance();

  locator.registerSingleton(Model(Loader(), prefs));
  locator.registerSingleton(Firebase());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Model>(create: (_) => locator<Model>()),
      ],
      child: Exolutio(),
    ),
  );
}
