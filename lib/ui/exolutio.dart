import 'package:exolutio/ui/routes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'deeplink.dart';
import 'home/screen.dart';
import 'messages.dart';
import 'read/screen.dart';

class Exolutio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exolutio',
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Merriweather_Sans',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Merriweather_Sans',
      ),
      initialRoute: Routes.home,
      routes: {
        Routes.home: (context) => _multiProviderHome(),
        Routes.read: (context) => ReadScreen(context),
      },
      // https://github.com/Sub6Resources/flutter_html/issues/294#issuecomment-637318948
      builder: (BuildContext context, Widget child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
        child: child,
      ),
    );
  }

  Provider<DeepRouter> _multiProviderHome() {
    MultiProvider(
      providers: [
        Provider<DeepRouter>(
          create: (context) => DeepRouter(context),
          lazy: false,
        ),
        Provider<PushRouter>(
          create: (context) => PushRouter(context),
          lazy: false,
        ),
      ],
      child: HomeScreen(),
    );
  }
}
