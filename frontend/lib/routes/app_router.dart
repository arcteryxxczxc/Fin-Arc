// lib/routes/app_router.dart
import 'package:flutter/material.dart';

// Screens
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/debug/api_test_screen.dart';
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
          builder: (_) => const SplashScreen(),
        );

      case RouteNames.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case RouteNames.register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case RouteNames.changePassword:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ChangePasswordScreen(),
        );

      case RouteNames.dashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );

      case RouteNames.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfileScreen(),
        );
        
      case RouteNames.apiTest:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ApiTestScreen(),
        );

      case RouteNames.reports:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ReportsScreen(),
        );

      case RouteNames.monthlyReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MonthlyReportScreen(),
        );

      case RouteNames.annualReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AnnualReportScreen(),
        );

      case RouteNames.budgetReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BudgetReportScreen(),
        );

      case RouteNames.cashflowReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CashflowReportScreen(),
        );

      case RouteNames.expenseList:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ExpenseListScreen(),
        );

      case RouteNames.expenseDetail:
        final int expenseId = args['expenseId'] ?? 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ExpenseDetailScreen(expenseId: expenseId),
        );

      case RouteNames.addExpense:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddExpenseScreen(),
        );

      // Income Routes
      case RouteNames.incomeList:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const IncomeListScreen(),
        );

      case RouteNames.incomeDetail:
        final int incomeId = args['incomeId'] ?? 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IncomeDetailScreen(incomeId: incomeId),
        );

      case RouteNames.addIncome:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AddIncomeScreen(),
        );

      case RouteNames.editIncome:
        final int incomeId = args['incomeId'] ?? 0;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EditIncomeScreen(incomeId: incomeId),
        );

      default:
        // If the route doesn't exist, show an error page
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Route not found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Add debug info button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(_).pushNamed(RouteNames.apiTest);
                    },
                    child: const Text('Run API Diagnostics'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}