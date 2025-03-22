import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:admin_side/screens/admin_auth_screen.dart';
import 'package:admin_side/screens/admin_home_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background notification: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    // _requestNotificationPermissions();
    // _getFCMToken();
    // _listenForNotifications();
  }

  void _requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Notification permission granted!");
    }
  }

  // void _getFCMToken() async {
  //   String? token = await FirebaseMessaging.instance.getToken();
  //   if (token != null) {
  //     await FirebaseFirestore.instance
  //         .collection('admin_tokens')
  //         .doc('admin')
  //         .set({'token': token});
  //   }
  // }

  // void _listenForNotifications() {
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print("New notification received: ${message.notification?.title}");

  //     showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text(message.notification?.title ?? "New Notification"),
  //           content: Text(
  //             message.notification?.body ?? "You have received an order.",
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text("OK"),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   });

  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     print("Notification clicked: ${message.notification?.title}");
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Midnight Munchies',
      initialRoute: '/login',
      routes: {
        '/login':
            (context) => AuthScreen(
              onRegistrationComplete: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
