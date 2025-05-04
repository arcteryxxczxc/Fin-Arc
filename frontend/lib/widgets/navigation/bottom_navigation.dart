// lib/widgets/navigation/bottom_navigation.dart
import 'package:flutter/material.dart';
import '../../routes/route_names.dart';

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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(),
      onTap: onTabTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_downward),
          label: 'Expenses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.arrow_upward),
          label: 'Income',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
  
  int _getCurrentIndex() {
    switch (currentRoute) {
      case RouteNames.dashboard:
        return 0;
      case RouteNames.expenseList:
      case RouteNames.expenseDetail:
      case RouteNames.addExpense:
      case RouteNames.editExpense:
        return 1;
      case RouteNames.incomeList:
      case RouteNames.incomeDetail:
      case RouteNames.addIncome:
      case RouteNames.editIncome:
        return 2;
      case RouteNames.categoryList:
      case RouteNames.categoryDetail:
      case RouteNames.addCategory:
      case RouteNames.editCategory:
        return 3;
      case RouteNames.reports:
      case RouteNames.monthlyReport:
      case RouteNames.annualReport:
      case RouteNames.budgetReport:
      case RouteNames.cashflowReport:
        return 4;
      case RouteNames.profile:
        return 5;
      default:
        return 0;
    }
  }
}