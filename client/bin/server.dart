import 'dart:io';

import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/loader.dart';
import 'package:firebase_cloud_messaging_backend/firebase_cloud_messaging_backend.dart';
import 'package:firedart/firedart.dart';

void main() async {
  final auth = await FirebaseAuth(
    // Firebase : Settings : General
    Platform.environment['FIREBASE_WEB_API_KEY'],
    await VolatileStore(),
  )
    ..signInAnonymously();

  final store = Firestore('exolutio', auth: auth);
  final links = store.collection('links');
  final current = await HtmlModel(Loader()).loadMore();
  final earlier = (await links.get()).map((e) => Link.fromMap(e.map)).toList();

  final sender = FirebaseCloudMessagingServer(
    _credentials(),
    'exolutio',
  );

  var updated = false;

  for (final link in current) {
    if (_notAny(earlier, link)) {
      print('Found new link: $link');
      await links.add(link.toMap());
      print('Link added to database');
      final response = await _broadcastNotification(sender, link);
      print(
        'Link broadcasted. FCM response: { '
        'statusCode: ${response.statusCode}, '
        'successful: ${response.successful}, }',
      );
      updated = true;
      break;
    }
  }

  for (final link in earlier) {
    if (_notAny(current, link)) {
      await links.document(link.url).delete();
      print('Removed old link: $link');
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

Future<ServerResult> _broadcastNotification(
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
