// lib/widgets/layout/screen_wrapper.dart
import 'package:flutter/material.dart';
import '../navigation/bottom_navigation.dart';
import '../../routes/route_names.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final bool showBottomNav;
  
  const ScreenWrapper({
    super.key,
    required this.child,
    required this.currentRoute,
    this.showBottomNav = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: showBottomNav
          ? FinArcBottomNavigation(
              currentRoute: currentRoute,
              onTabTapped: (index) => _navigateToTab(context, index),
            )
          : null,
    );
  }
  
  void _navigateToTab(BuildContext context, int index) {
    String route;
    
    switch (index) {
      case 0:
        route = RouteNames.dashboard;
        break;
      case 1:
        route = RouteNames.expenseList;
        break;
      case 2:
        route = RouteNames.incomeList;
        break;
      case 3:
        route = RouteNames.categoryList;
        break;
      case 4:
        route = RouteNames.reports;
        break;
      case 5:
        route = RouteNames.profile;
        break;
      default:
        route = RouteNames.dashboard;
    }
    
    // Only navigate if not already on the selected route
    if (currentRoute != route) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }
}