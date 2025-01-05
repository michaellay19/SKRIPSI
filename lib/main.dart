import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/all_pages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:skripsi/pages/login_page.dart';
import 'package:skripsi/provider/auth_provider.dart';
import 'package:skripsi/provider/camera_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => CameraProvider()),
      ChangeNotifierProvider(create: (context) => MyAuthProvider()),
    ],
    child: MyApp(),
    ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<MyAuthProvider>(context);

    return authProvider.user == null ? LoginPage() : AllPages();
  }
}