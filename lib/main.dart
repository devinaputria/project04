import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

 await Supabase.initialize(
  url: 'https://irzzxfolpxfhniwlemts.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlyenp4Zm9scHhmaG5pd2xlbXRzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5ODM2MzksImV4cCI6MjA3MzU1OTYzOX0.s8BL-RCpfN3dGuZQMzCzRklrekxR5juyisbGUIaPPys',
);

  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  static const Color primaryDarkBlue = Color(0xFF002A96);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Data Diri Siswa',
      theme: ThemeData(
        primaryColor: primaryDarkBlue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primaryDarkBlue,
          secondary: Colors.blueGrey,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
