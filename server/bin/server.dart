import 'dart:io';

import 'package:firebase_cloud_messaging_backend/firebase_cloud_messaging_backend.dart';
import 'package:firedart/firedart.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';

void main() async {
  final links = Firestore(
    'exolutio',
    auth: await _firebaseAuth(),
  ).collection('links');

  final current = (await HtmlModel(Loader())
    ..loadMore())[Tag.any];
  final earlier = (await links.get()).map(
    (e) => LinkData.fromMap(e.map),
  );

  final notifier = FirebaseCloudMessagingServer(
    _credentials(),
    'exolutio',
  );

  final added = _missing(
    from: earlier,
    list: current,
  ).map((e) => _notify(e, links, notifier));

  final clean = _missing(
    from: current,
    list: earlier,
  ).map((e) => _delete(e, links));

  if ((await Future.wait([...added, ...clean])).length > 0) {
    print('Firestore updated');
  } else {
    print('No changes found');
  }

  exit(0);
}

Iterable<LinkData> _missing(
    {Iterable<LinkData> from, Iterable<LinkData> list}) {
  return list.where((e) => _notAny(from, e));
}

Future<FirebaseAuth> _firebaseAuth() async {
  return await FirebaseAuth(
    // Firebase : Settings : General
    Platform.environment['FIREBASE_WEB_API_KEY'],
    await VolatileStore(),
  )
    ..signInAnonymously();
}

Future _notify(
  LinkData link,
  CollectionReference links,
  FirebaseCloudMessagingServer notifier,
) async {
  print('Found new link: $link');
  await links.add(link.toMap());
  print('Link added to database');
  await _send(notifier, link);
  print('Users notified');
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
