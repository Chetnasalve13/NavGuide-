import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:navguide/home/options/google_nav.dart';
import 'package:navguide/home/options/saved_routes.dart';
import 'package:navguide/home/options/settings.dart';
import 'package:navguide/session/userProvider.dart';
import 'package:provider/provider.dart';
import 'home/home.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.yellow,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              foregroundColor: Colors.black,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.yellow),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        home: const AuthCheck(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/start_navigation': (context) => const StartNavigationPage(),
          '/settings': (context) => SettingsPage(),
          '/saved_routes': (context) => SavedRoutesPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;

          if (user != null) {
            // Fetch and store user data when the user is authenticated
            Provider.of<UserProvider>(context, listen: false)
                .fetchUserData()
                .then((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return const LoginPage();
          }
        } else {
          return Scaffold(
            body: Center(
                child: CircularProgressIndicator()), // Show loading indicator
          );
        }
      },
    );
  }
}
