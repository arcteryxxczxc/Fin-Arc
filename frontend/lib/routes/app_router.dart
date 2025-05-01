// lib/routes/app_router.dart
import 'package:flutter/material.dart';

// Screens
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/expenses/expense_list_screen.dart';
import '../screens/expenses/expense_detail_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/income/income_list_screen.dart';
import '../screens/income/income_detail_screen.dart';
import '../screens/income/add_income_screen.dart';
import '../screens/income/edit_income_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/monthly_report_screen.dart';
import '../screens/reports/annual_report_screen.dart';
import '../screens/reports/budget_report_screen.dart';
import '../screens/reports/cashflow_report_screen.dart';

// Routes
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if available
    final args = settings.arguments as Map<String, dynamic>? ?? {};
    
    switch (settings.name) {
      case '/':
      case RouteNames.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SplashScreen()
        );
        
      case RouteNames.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => LoginScreen()
        );
        
      case RouteNames.register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RegisterScreen()
        );
        
      case RouteNames.changePassword:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangePasswordScreen()
        );
        
      case RouteNames.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DashboardScreen()
        );
        
      case RouteNames.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileScreen()
        );
        
      case RouteNames.reports:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ReportsScreen()
        );
        
      case RouteNames.monthlyReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MonthlyReportScreen()
        );
        
      case RouteNames.annualReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AnnualReportScreen()
        );
        
      case RouteNames.budgetReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BudgetReportScreen()
        );
        
      case RouteNames.cashflowReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CashflowReportScreen()
        );

      case RouteNames.expenseList:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExpenseListScreen()
        );
        
      case RouteNames.expenseDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExpenseDetailScreen(
            expenseId: args['expenseId'],
          )
        );
        
      case RouteNames.addExpense:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AddExpenseScreen()
        );
      
      // Income Routes  
      case RouteNames.incomeList:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IncomeListScreen()
        );
        
      case RouteNames.incomeDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IncomeDetailScreen(
            incomeId: args['incomeId'],
          )
        );
        
      case RouteNames.addIncome:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AddIncomeScreen()
        );
        
      case RouteNames.editIncome:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EditIncomeScreen(
            incomeId: args['incomeId'],
          )
        );
        
      // Add more routes as needed for categories, etc.
        
      default:
        // If the route doesn't exist, show an error page
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Route not found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('The page you requested could not be found.'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(_).pushReplacementNamed(RouteNames.dashboard),
                    child: Text('Go to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}