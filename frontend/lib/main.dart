import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Add more providers here as needed
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Fin-Arc',
          theme: ThemeData(
            primaryColor: Color(0xFF001F3F),
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Color(0xFFF8F9FA),
            // Additional theme settings
            appBarTheme: AppBarTheme(
              backgroundColor: Color(0xFF001F3F),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF001F3F),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          home: FutureBuilder(
            future: auth.initAuth(),
            builder: (ctx, snapshot) {
              // Show splash screen while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen();
              }
              // Navigate based on auth state
              return auth.isAuthenticated ? DashboardScreen() : LoginScreen();
            },
          ),
          routes: {
            '/login': (ctx) => LoginScreen(),
            '/register': (ctx) => RegisterScreen(),
            '/dashboard': (ctx) => DashboardScreen(),
            // Additional routes
          },
        ),
      ),
    );
  }
}