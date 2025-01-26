import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/auth/splash_page.dart';
import 'package:skripsi/provider/auth_provider.dart';
import 'package:skripsi/provider/camera_provider.dart';
import 'package:skripsi/provider/profile_provider.dart';
import 'package:skripsi/provider/request_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyC49Z8bJ9rZi8E1wRq38fQo-_fq71ivBAE",
            authDomain: "amitofochat.firebaseapp.com",
            projectId: "amitofochat",
            storageBucket: "amitofochat",
            messagingSenderId: "420716583804",
            appId: "1:420716583804:web:4cedd74dce44df8404a2f9",
            measurementId: "G-8QGWCRNJWY",
          )
        : null,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => MyAuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const SplashScreen(),
    );
  }
}