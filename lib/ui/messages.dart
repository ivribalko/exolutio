import 'package:exolutio/src/model.dart';
import 'package:exolutio/ui/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class PushRouter {
  final BuildContext context;

  PushRouter(this.context) {
    _setUpPushNotifications();
  }

  Future _setUpPushNotifications() async {
    final firebaseMessaging = FirebaseMessaging();
    await firebaseMessaging.requestNotificationPermissions();
    firebaseMessaging.configure(
      onMessage: _handleNotification,
      onLaunch: _handleNotification,
      onResume: _handleNotification,
    );
  }

  Future<dynamic> _handleNotification(Map<String, dynamic> data) async {
    Navigator.of(context).pushNamed(
      Routes.read,
      arguments: Link.fromMap(data),
    );
  }
}
