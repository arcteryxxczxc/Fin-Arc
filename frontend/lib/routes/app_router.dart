import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expense_list_screen.dart';
import '../screens/expenses/expense_detail_screen.dart';
import '../screens/expenses/add_expense_screen.dart';
import '../screens/income/income_list_screen.dart';
import '../screens/income/income_detail_screen.dart';
import '../screens/income/add_income_screen.dart';
import '../screens/categories/category_list_screen.dart';
import '../screens/categories/category_detail_screen.dart';
import '../screens/categories/category_form_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/reports/monthly_report_screen.dart';
import '../screens/reports/annual_report_screen.dart';
import '../screens/reports/budget_report_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
        
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
        
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
        
      case RouteNames.changePassword:
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());
        
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
        
      case RouteNames.expenseList:
        return MaterialPageRoute(builder: (_) => ExpenseListScreen());
        
      case RouteNames.expenseDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final expenseId = args['expenseId'] as int;
        return MaterialPageRoute(
          builder: (_) => ExpenseDetailScreen(expenseId: expenseId),
        );
        
      case RouteNames.addExpense:
        final args = settings.arguments as Map<String, dynamic>?;
        final expenseId = args?['expenseId'] as int?;
        return MaterialPageRoute(
          builder: (_) => AddExpenseScreen(expenseId: expenseId),
        );
        
      case RouteNames.incomeList:
        return MaterialPageRoute(builder: (_) => income_list_screen.IncomeListScreen());
        
      case RouteNames.incomeDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final incomeId = args['incomeId'] as int;
        return MaterialPageRoute(
          builder: (_) => income_detail_screen.IncomeDetailScreen(incomeId: incomeId),
        );
        
      case RouteNames.addIncome:
        return MaterialPageRoute(builder: (_) => AddIncomeScreen());
        
      case RouteNames.categoryList:
        return MaterialPageRoute(builder: (_) => CategoryListScreen());
        
      case RouteNames.categoryDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final categoryId = args['categoryId'] as int;
        return MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(categoryId: categoryId),
        );
        
      case RouteNames.addCategory:
        final args = settings.arguments as Map<String, dynamic>?;
        final isExpense = args?['isExpense'] as bool? ?? true;
        return MaterialPageRoute(
          builder: (_) => CategoryFormScreen(isExpense: isExpense),
        );
        
      case RouteNames.editCategory:
        final args = settings.arguments as Map<String, dynamic>;
        final category = args['category'];
        return MaterialPageRoute(
          builder: (_) => CategoryFormScreen(category: category),
        );
        
      case RouteNames.reports:
        return MaterialPageRoute(builder: (_) => ReportsScreen());
        
      case RouteNames.monthlyReport:
        return MaterialPageRoute(builder: (_) => MonthlyReportScreen());
        
      case RouteNames.annualReport:
        return MaterialPageRoute(builder: (_) => AnnualReportScreen());
        
      case RouteNames.budgetReport:
        return MaterialPageRoute(builder: (_) => BudgetReportScreen());
        
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
        
      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => settings_screen.SettingsScreen());
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}