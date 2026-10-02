import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraAndMicPermission() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  static Future<bool> requestStoragePermission() async {
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    final notification = await Permission.notification.request();
    return notification.isGranted;
  }
}
