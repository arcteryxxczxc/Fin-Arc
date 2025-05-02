// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Dev tools
import 'dart:developer';

// Providers
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/income_provider.dart';
import 'providers/category_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

// Routes
import 'routes/app_router.dart';
import 'routes/route_observer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Add global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    log('Flutter error: ${details.exception}');
    log('Stack trace: ${details.stack}');
  };
  
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

  MyApp({super.key});
  
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
        ChangeNotifierProvider(create: (_) => CategoryProvider()), // Added
        
        // Route observer as a value notifier provider
        Provider<FinArcRouteObserver>.value(value: routeObserver),
        
        // Provide current route as a stream
        StreamProvider<String>(
          create: (_) => routeObserver.stream,
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
          home: const AuthenticationWrapper(),
        ),
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  late Future<void> _authFuture;
  
  @override
  void initState() {
    super.initState();
    log('Initializing AuthenticationWrapper');
    // Get the auth provider but don't listen to it here
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Initialize the auth future only once
    _authFuture = authProvider.initAuth();
  }
  
  @override
  Widget build(BuildContext context) {
    log('Building AuthenticationWrapper');
    // Listen to auth provider changes for UI updates
    final authProvider = Provider.of<AuthProvider>(context);
    
    return FutureBuilder(
      future: _authFuture,
      builder: (ctx, snapshot) {
        // Log the current state for debugging
        log('Auth Future state: ${snapshot.connectionState}');
        
        // Show error if authentication initialization failed
        if (snapshot.hasError) {
          log('Auth initialization error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Authentication Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      log('Retrying authentication');
                      setState(() {
                        _authFuture = authProvider.initAuth();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          log('Auth state is loading, showing splash screen');
          return const SplashScreen();
        }
        
        // Handle any error from the auth provider
        if (authProvider.error != null) {
          log('Auth provider error: ${authProvider.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Authentication Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(authProvider.error ?? 'Unknown error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      log('Clearing error and retrying');
                      authProvider.clearError();
                      setState(() {
                        _authFuture = authProvider.initAuth();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Load initial data if authenticated
        if (authProvider.isAuthenticated) {
          log('User is authenticated, showing dashboard');
          return const DashboardScreen();
        }
        
        // Not authenticated, show login screen
        log('User is not authenticated, showing login screen');
        return const LoginScreen();
      },
    );
  }
}