// lib/routes/route_names.dart
class RouteNames {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String changePassword = '/change-password';
  
  // Main
  static const String dashboard = '/dashboard';
  
  // Expenses
  static const String expenseList = '/expenses';
  static const String expenseDetail = '/expenses/detail';
  static const String addExpense = '/expenses/add';
  static const String editExpense = '/expenses/edit';
  
  // Income
  static const String incomeList = '/income';
  static const String incomeDetail = '/income/detail';
  static const String addIncome = '/income/add';
  static const String editIncome = '/income/edit';
  
  // Categories
  static const String categoryList = '/categories';
  static const String categoryDetail = '/categories/detail';
  static const String addCategory = '/categories/add';
  static const String editCategory = '/categories/edit';
  static const String categoryBudget = '/categories/budget';
  
  // Reports
  static const String reports = '/reports';
  static const String monthlyReport = '/reports/monthly';
  static const String annualReport = '/reports/annual';
  static const String budgetReport = '/reports/budget';
  static const String cashflowReport = '/reports/cashflow';
  static const String financialInsights = '/reports/insights';
  
  // User
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String loginHistory = '/profile/login-history';
  
  // Settings
  static const String settings = '/settings';
  static const String currencySettings = '/settings/currency';
  static const String notificationSettings = '/settings/notifications';
  
  // Help & Support
  static const String helpSupport = '/help/support';
  static const String privacyPolicy = '/help/privacy-policy';
  static const String termsOfService = '/help/terms-of-service';
  
  // Debug tools
  static const String apiTest = '/debug/api-test';
}