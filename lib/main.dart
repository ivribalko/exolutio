import 'package:evotexto/src/model.dart';
import 'package:evotexto/ui/evotexto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Wakelock.enable();
  }

  final prefs = await SharedPreferences.getInstance();
  final model = ArticleModel(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ArticleModel>(create: (_) => model),
      ],
      child: FutureBuilder(
        future: model.links,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error));
              } else {
                return Evotexto(model, snapshot.data);
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
