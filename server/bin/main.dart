import 'dart:io';

import 'package:firebase_cloud_messaging_backend/firebase_cloud_messaging_backend.dart';
import 'package:firedart/firedart.dart';
import 'package:shared/html_model.dart';
import 'package:shared/loader.dart';

void main() async {
  final auth = await _firebaseAuth();
  final links = Firestore('exolutio', auth: auth).collection('links');
  final current = await HtmlModel(Loader()).loadMore();
  final earlier = (await links.get()).map((e) => Link.fromMap(e.map)).toList();

  final sender = FirebaseCloudMessagingServer(
    _credentials(),
    'exolutio',
  );

  var updated = false;

  for (final link in current) {
    if (_notAny(earlier, link)) {
      await _saveSend(link, links, sender);
      updated = true;
    }
  }

  for (final link in earlier) {
    if (_notAny(current, link)) {
      await _delete(links, link);
      updated = true;
    }
  }

  if (updated) {
    print('Firestore updated');
  } else {
    print('No changes found');
  }

  exit(0);
}

Future<FirebaseAuth> _firebaseAuth() async {
  return await FirebaseAuth(
    // Firebase : Settings : General
    Platform.environment['FIREBASE_WEB_API_KEY'],
    await VolatileStore(),
  )
    ..signInAnonymously();
}

Future _saveSend(
  Link link,
  CollectionReference links,
  FirebaseCloudMessagingServer sender,
) async {
  print('Found new link: $link');
  await links.add(link.toMap());
  print('Link added to database');
  final response = await _notify(sender, link);
  print('Users notified. $response');
}

Future _delete(CollectionReference links, Link link) async {
  await links.document(link.url).delete();
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

Future<ServerResult> _notify(
  FirebaseCloudMessagingServer server,
  Link link,
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

bool _notAny(List<Link> list, Link link) {
  return !list.any((e) => e.url == link.url);
}
