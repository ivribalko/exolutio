import 'dart:io';

import 'package:firebase_cloud_messaging_backend/firebase_cloud_messaging_backend.dart';
import 'package:firedart/firedart.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';

const dryRunArg = '--dry-run';
const noNotifyArg = '--no-notify';

var dryRun = false;
var noNotify = false;

void main(List<String> args) async {
  if (args.isNotEmpty) {
    switch (args[0]) {
      case dryRunArg:
        dryRun = true;
        break;
      case noNotifyArg:
        noNotify = true;
        break;
      case '?':
      case '-h':
      case '--help':
        print('$dryRunArg\n$noNotifyArg');
        return;
    }
  }

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
    // Firebase : Settings : General
    Platform.environment['FIREBASE_WEB_API_KEY'],
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
  return JWTClaim.from(
    File.fromUri(
      Uri.file(
        // https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform
        Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'],
      ),
    ),
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
