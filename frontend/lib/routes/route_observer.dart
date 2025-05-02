// lib/routes/route_observer.dart
import 'package:flutter/material.dart';

class FinArcRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  final ValueNotifier<String> currentRoute = ValueNotifier<String>('/');
  
  Stream<String> get stream {
    late StreamController<String> controller;
    
    void listener() {
      controller.add(currentRoute.value);
    }
    
    controller = StreamController<String>(
      onListen: () {
        currentRoute.addListener(listener);
        // Immediately provide the current value
        controller.add(currentRoute.value);
      },
      onCancel: () {
        currentRoute.removeListener(listener);
        controller.close();
      },
    );
    
    return controller.stream;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _updateCurrentRoute(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _updateCurrentRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _updateCurrentRoute(previousRoute);
    }
  }
  
  void _updateCurrentRoute(PageRoute route) {
    // Extract route name from settings
    final String? routeName = route.settings.name;
    if (routeName != null) {
      currentRoute.value = routeName;
    }
  }
}