import 'package:evotexto/src/model.dart';
import 'package:evotexto/ui/evotexto.dart';
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

  locator.registerSingleton(Model(prefs));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Model>(create: (_) => locator<Model>()),
      ],
      child: FutureBuilder(
        future: locator<Model>().links,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error));
              } else {
                return Evotexto(locator<Model>(), snapshot.data);
              }
              break;
            default:
              return Center(child: CircularProgressIndicator());
          }
        },
      ),
    ),
  );
}
