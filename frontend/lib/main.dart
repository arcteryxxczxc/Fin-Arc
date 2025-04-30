import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/category_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider should be first as others depend on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Data providers
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) => MaterialApp(
          title: 'Fin-Arc',
          theme: themeProvider.themeData,
          debugShowCheckedModeBanner: false,
          home: AuthenticationWrapper(),
          routes: {
            '/login': (ctx) => LoginScreen(),
            '/register': (ctx) => RegisterScreen(),
            '/dashboard': (ctx) => DashboardScreen(),
          },
        ),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Initialize other providers once authenticated
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    
    return FutureBuilder(
      future: authProvider.initAuth(),
      builder: (ctx, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        
        // Load initial data if authenticated
        if (authProvider.isAuthenticated) {
          // Preload categories for the app to use
          categoryProvider.fetchCategories();
          return DashboardScreen();
        }
        
        // Not authenticated, show login screen
        return LoginScreen();
      },
    );
  }
}