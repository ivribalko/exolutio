import 'dart:io';

import 'package:exolutio/src/html_model.dart';
import 'package:exolutio/src/loader.dart';
import 'package:firebase_cloud_messaging_backend/firebase_cloud_messaging_backend.dart';
import 'package:firedart/firedart.dart';

void main() async {
  final server = FirebaseCloudMessagingServer(
    JWTClaim.from(_credentialsFile),
    'exolutio',
  );

  final auth = await FirebaseAuth(
    // Firebase : Settings : General
    Platform.environment['FIREBASE_WEB_API_KEY'],
    await VolatileStore(),
  )
    ..signInAnonymously();

  final store = Firestore('exolutio', auth: auth).collection('titles');
  final current = await HtmlModel(Loader()).loadMore();
  final earlier = (await store.get()).map((e) => Link.fromMap(e.map)).toList();

  var updated = false;

  for (final link in current) {
    if (_notAny(earlier, link)) {
      print('Found new link: $link');
      await store.add(link.toMap());
      print('Link added to database');
      final response = await _broadcastNotification(server, link);
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
      await store.document(link.url).delete();
      print('Removed old link: $link');
    }
  }

  if (updated) {
    print('Firestore updated with new titles');
  } else {
    print('No new titles found, updated skipped');
  }

  exit(0);
}

File get _credentialsFile {
  return File.fromUri(
    Uri.file(
      // https://firebase.google.com/docs/cloud-messaging/auth-server
      Platform.environment['GOOGLE_APPLICATION_CREDENTIALS'],
    ),
  );
}

Future<ServerResult> _broadcastNotification(
    FirebaseCloudMessagingServer server, Link link) {
  return server.send(
    Send(
      message: Message(
        notification: Notification(
          body: 'Появилась новая статья - ${link.title}',
        ),
        topic: 'new-content',
        data: link.toMap()..['click_action'] = 'FLUTTER_NOTIFICATION_CLICK',
      ),
    ),
  );
}

bool _notAny(List<Link> list, Link link) {
  return !list.any((e) => e.url == link.url);
}
