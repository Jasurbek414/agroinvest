import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/dio_client.dart';

/// Push notification wiring - INFRASTRUCTURE ONLY. The backend already has a
/// `fcm_token` column on `users` and a NotificationChannel.PUSH enum value;
/// what was missing end-to-end was every piece of the FCM plumbing itself, so
/// notifications only ever worked while the app was open and polling.
///
/// This stays completely inert until a real Firebase project is attached:
/// 1. Create a Firebase project, register the Android/iOS apps.
/// 2. Drop `google-services.json` into `android/app/` and
///    `GoogleService-Info.plist` into `ios/Runner/` (and wire the Gradle
///    `google-services` plugin - not done here, since there is nothing to
///    point it at yet).
/// 3. Call `PushNotificationService().initialize()` once after login succeeds
///    (e.g. in AuthProvider right after `_saveSession`, or in
///    AppShellScaffold.initState alongside the existing unread-count fetch).
///
/// Until step 3 is added somewhere in the app's startup/login path, this
/// class is simply never invoked - adding the packages and this file changes
/// nothing about current app behavior.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      messaging.onTokenRefresh.listen(_registerToken);

      // Foreground messages currently have no UI treatment decided (banner?
      // in-app toast? silent + rely on the existing unread-count badge?) -
      // left as an explicit no-op hook rather than guessing.
      FirebaseMessaging.onMessage.listen((message) {});

      _initialized = true;
    } catch (e) {
      // No Firebase project configured yet (or any other native setup gap) -
      // push notifications simply stay off; the rest of the app is unaffected.
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await DioClient().dio.patch('/users/me/fcm-token', data: {'fcmToken': token});
    } catch (_) {
      // Non-critical - retried next time initialize() runs (e.g. next login).
    }
  }
}
