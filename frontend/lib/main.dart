// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

// Routes
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'routes/route_observer.dart';

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
  // Create a route observer to track navigation
  final FinArcRouteObserver routeObserver = FinArcRouteObserver();
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider should be first as others depend on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Feature providers
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => IncomeProvider()),
        
        // Route observer as a value notifier provider
        Provider<FinArcRouteObserver>.value(value: routeObserver),
        
        // Provide current route as a stream
        StreamProvider<String>(
          create: (_) => routeObserver.currentRoute.stream,
          initialData: '/',
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) => MaterialApp(
          title: 'Fin-Arc',
          theme: themeProvider.themeData,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          navigatorObservers: [routeObserver],
          onGenerateRoute: AppRouter.generateRoute,
          home: AuthenticationWrapper(),
        ),
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return FutureBuilder(
      future: authProvider.initAuth(),
      builder: (ctx, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        
        // Load initial data if authenticated
        if (authProvider.isAuthenticated) {
          // Initialize other providers as needed
          return DashboardScreen();
        }
        
        // Not authenticated, show login screen
        return LoginScreen();
      },
    );
  }
}