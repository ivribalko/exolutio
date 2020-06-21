import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Wakelock.enable();
  }

  runApp(Evotexto());
}

class Evotexto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evotexto',
      home: FutureBuilder(
        future: Future.delayed(Duration(seconds: 1)).then((value) => 'result'),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error));
              } else {
                return Center(child: Text(snapshot.data));
              }
              break;
            default:
              return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
