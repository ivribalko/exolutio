import 'package:evotexto/src/model.dart';
import 'package:evotexto/ui/evotexto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Wakelock.enable();
  }

  final model = ArticleModel();

  runApp(
    FutureBuilder(
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
  );
}
