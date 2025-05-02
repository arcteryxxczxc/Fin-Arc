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

        // Feature providers - add these lazily after auth is initialized
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, auth, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, IncomeProvider>(
          create: (_) => IncomeProvider(),
          update: (_, auth, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, CategoryProvider>(
          create: (_) => CategoryProvider(),
          update: (_, auth, previous) => previous!,
        ),
        
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
  bool _isInitializing = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    log('Initializing AuthenticationWrapper');
    // Get the auth provider but don't listen to it here
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.initAuth();
    } catch (e) {
      log('Auth initialization error in wrapper: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    log('Building AuthenticationWrapper, isInitializing: $_isInitializing');
    // Listen to auth provider changes for UI updates
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Show splash screen while initializing
    if (_isInitializing) {
      log('Still initializing, showing splash screen');
      return const SplashScreen();
    }
    
    // Show error screen if there's an initialization error
    if (_errorMessage != null) {
      log('Showing error screen: $_errorMessage');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  log('Retrying authentication');
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initializeAuth();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Handle any error from the auth provider
    if (authProvider.error != null) {
      log('Auth provider error: ${authProvider.error}');
      // We don't show a full error screen for auth provider errors 
      // as they might be transient and related to specific operations
    }
    
    // Load initial data if authenticated
    if (authProvider.isAuthenticated) {
      log('User is authenticated, showing dashboard');
      return const DashboardScreen();
    }
    
    // Not authenticated, show login screen
    log('User is not authenticated, showing login screen');
    return const LoginScreen();
  }
}