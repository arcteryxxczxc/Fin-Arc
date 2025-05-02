// lib/widgets/navigation/bottom_navigation.dart
import 'package:flutter/material.dart';
import '../../routes/route_names.dart';
import '../../utils/color_utils.dart'; 

class FinArcBottomNavigation extends StatelessWidget {
  final String currentRoute;
  final Function(int) onTabTapped;
  
  const FinArcBottomNavigation({
    super.key,
    required this.currentRoute,
    required this.onTabTapped,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine the current index based on the route
    int currentIndex = _getSelectedIndex(currentRoute);
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: ColorUtils.withOpacity(Colors.black, 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        color: theme.cardColor,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 0,
        items: [
          _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
          _buildNavItem(Icons.arrow_downward_outlined, Icons.arrow_downward, 'Expenses'),
          _buildNavItem(Icons.arrow_upward_outlined, Icons.arrow_upward, 'Income'),
          _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 'Reports'),
          _buildNavItem(Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }
  
  // Helper method to build navigation items
  BottomNavigationBarItem _buildNavItem(IconData iconOutlined, IconData iconFilled, String label) {
    return BottomNavigationBarItem(
      icon: Icon(iconOutlined),
      activeIcon: Icon(iconFilled),
      label: label,
    );
  }
  
  // Get the selected index based on the current route
  int _getSelectedIndex(String currentRoute) {
    if (currentRoute.startsWith(RouteNames.dashboard)) {
      return 0;
    } else if (currentRoute.startsWith('/expenses')) {
      return 1;
    } else if (currentRoute.startsWith('/income')) {
      return 2;
    } else if (currentRoute.startsWith('/reports')) {
      return 3;
    } else if (currentRoute.startsWith(RouteNames.profile) || 
              currentRoute.startsWith(RouteNames.settings)) {
      return 4;
    }
    return 0; 
  }
}