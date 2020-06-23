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

  locator.registerSingleton(Model(prefs));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Model>(create: (_) => locator<Model>()),
      ],
      child: Selector<Model, bool>(
        selector: (_, Model model) => model.mail,
        builder: (_, bool mail, __) {
          return FutureBuilder(
            future: mail ? locator<Model>().letters : locator<Model>().others,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error));
                  } else {
                    return Exolutio(locator<Model>(), snapshot.data);
                  }
                  break;
                default:
                  return Center(child: CircularProgressIndicator());
              }
            },
          );
        },
      ),
    ),
  );
}
