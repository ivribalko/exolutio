import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:firebase_cloud_messaging_backend/firebase_cloud_messaging_backend.dart';
import 'package:firedart/firedart.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';

// https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform
var googleCredentials = Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'];
// Firebase : Settings : General
var firebaseWebApiKey = Platform.environment['FIREBASE_WEB_API_KEY'];

var dryRun = false;
var noNotify = false;

void main(List<String> args) async {
  setParameters(args);

  final html = HtmlModel(Loader());
  await html.loadMore();

  final links = Firestore(
    'exolutio',
    auth: await _firebaseAuth(),
  ).collection('links');

  final current = html[Tag.any];
  final earlier = (await links.get()).map(
    (e) => LinkData.fromMap(e.map),
  );

  if (current.isEmpty) {
    throw Exception('no articles found');
  }

  final notifier = FirebaseCloudMessagingServer(
    _credentials(),
    'exolutio',
  );

  final added = _missing(
    from: earlier,
    list: current,
  ).map(printLink).where((e) => !dryRun).map(
    (e) {
      return _addLink(e, links).then(
        (_) {
          if (!noNotify) {
            return _notify(e, notifier);
          }
        },
      );
    },
  );

  final clean = _missing(
    from: current,
    list: earlier,
  ).where((e) => !dryRun).map((e) => _delete(e, links));

  if ((await Future.wait([...added, ...clean])).length > 0) {
    print('Firestore updated');
  } else {
    print('No changes were made');
  }

  exit(0);
}

void setParameters(List<String> args) {
  const dryRunArg = 'dry-run';
  const noNotifyArg = 'no-notify';
  const googleArg = 'google-acc';
  const firebaseArg = 'firebase-web-key';

  var parsed = (ArgParser()
        ..addFlag(dryRunArg, defaultsTo: false)
        ..addFlag(noNotifyArg, defaultsTo: false)
        ..addOption(googleArg)
        ..addOption(firebaseArg))
      .parse(args);

  dryRun = parsed[dryRunArg];
  noNotify = parsed[noNotifyArg];
  googleCredentials = parsed[googleArg] ?? googleCredentials;
  firebaseWebApiKey = parsed[firebaseArg] ?? firebaseWebApiKey;

  if (googleCredentials?.isEmpty ?? true) {
    throw Exception('googleAppCredentials is null or empty');
  }

  if (firebaseWebApiKey?.isEmpty ?? true) {
    throw Exception('firebaseWebApiKey is null or empty');
  }
}

LinkData printLink(e) {
  print('Found new link: $e');
  return e;
}

Iterable<LinkData> _missing({
  Iterable<LinkData> from,
  Iterable<LinkData> list,
}) {
  return list.where((e) => _notAny(from, e));
}

Future<FirebaseAuth> _firebaseAuth() async {
  final auth = await FirebaseAuth(
    firebaseWebApiKey,
    await VolatileStore(),
  );

  await auth.signInAnonymously();

  return auth;
}

Future _notify(
  LinkData link,
  FirebaseCloudMessagingServer notifier,
) async {
  await _send(notifier, link);
  print('Users notified');
}

Future _addLink(LinkData link, CollectionReference links) async {
  await links.add(link.toMap());
  print('Link added to database');
}

Future _delete(LinkData link, CollectionReference links) async {
  final document = await links.where('url', isEqualTo: link.url).get();
  await document.first.reference.delete();
  print('Removed old link: $link');
}

JWTClaim _credentials() {
  return JWTClaim.fromJson(
    json.decode(googleCredentials),
  );
}

Future<ServerResult> _send(
  FirebaseCloudMessagingServer server,
  LinkData link,
) {
  return server.send(
    Send(
      message: Message(
        notification: Notification(
          title: 'Новая статья!',
          body: '${link.title} - перейти к чтению.',
        ),
        topic: 'new-content',
        data: link.toMap()..['click_action'] = 'FLUTTER_NOTIFICATION_CLICK',
        android: AndroidConfig(
          priority: AndroidMessagePriority.HIGH,
        ),
      ),
    ),
  );
}

bool _notAny(Iterable<LinkData> list, LinkData link) {
  return !list.any((e) => e.url == link.url);
}
