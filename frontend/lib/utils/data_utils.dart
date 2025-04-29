import 'package:intl/intl.dart';
import 'dart:math';
import '../models/expense.dart';
import '../models/income.dart';

/// Utility class for data formatting and analysis
class DataUtils {
  /// Format currency amount with the specified locale and currency symbol
  static String formatCurrency(double amount, {String locale = 'en_US', String currencySymbol = '\$'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol,
    );
    
    return formatter.format(amount);
  }
  
  /// Format date with the specified pattern
  static String formatDate(String dateString, {String pattern = 'MMM d, yyyy'}) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat(pattern).format(date);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
  
  /// Calculate total expenses for a list of expenses
  static double calculateTotalExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) return 0;
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
  
  /// Calculate total income for a list of income entries
  static double calculateTotalIncome(List<Income> incomes) {
    if (incomes.isEmpty) return 0;
    return incomes.fold(0, (sum, income) => sum + income.amount);
  }
  
  /// Calculate balance (income - expenses)
  static double calculateBalance(List<Income> incomes, List<Expense> expenses) {
    final totalIncome = calculateTotalIncome(incomes);
    final totalExpenses = calculateTotalExpenses(expenses);
    return totalIncome - totalExpenses;
  }
  
  /// Calculate savings rate as a percentage of income
  static double calculateSavingsRate(List<Income> incomes, List<Expense> expenses) {
    final totalIncome = calculateTotalIncome(incomes);
    if (totalIncome <= 0) return 0; // Avoid division by zero
    
    final totalExpenses = calculateTotalExpenses(expenses);
    final savings = totalIncome - totalExpenses;
    
    return (savings / totalIncome) * 100;
  }
  
  /// Filter transactions by date range
  static List<T> filterByDateRange<T>(
    List<T> items,
    DateTime startDate,
    DateTime endDate,
    String Function(T) getDateString,
  ) {
    return items.where((item) {
      try {
        final date = DateTime.parse(getDateString(item));
        return date.isAfter(startDate.subtract(Duration(days: 1))) && 
               date.isBefore(endDate.add(Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }
  
  /// Group expenses by category
  static Map<String, double> groupExpensesByCategory(List<Expense> expenses) {
    final Map<String, double> result = {};
    
    for (final expense in expenses) {
      final category = expense.categoryName ?? 'Uncategorized';
      result[category] = (result[category] ?? 0) + expense.amount;
    }
    
    return result;
  }
  
  /// Group income by source
  static Map<String, double> groupIncomeBySource(List<Income> incomes) {
    final Map<String, double> result = {};
    
    for (final income in incomes) {
      final source = income.source;
      result[source] = (result[source] ?? 0) + income.amount;
    }
    
    return result;
  }
  
  /// Group transactions by month
  static Map<String, double> groupByMonth<T>(
    List<T> items,
    String Function(T) getDateString,
    double Function(T) getAmount,
  ) {
    final Map<String, double> result = {};
    
    for (final item in items) {
      try {
        final date = DateTime.parse(getDateString(item));
        final monthKey = DateFormat('yyyy-MM').format(date);
        result[monthKey] = (result[monthKey] ?? 0) + getAmount(item);
      } catch (e) {
        // Skip items with invalid dates
        continue;
      }
    }
    
    return result;
  }
  
  /// Calculate monthly averages for expenses/income
  static double calculateMonthlyAverage<T>(
    List<T> items,
    String Function(T) getDateString,
    double Function(T) getAmount,
  ) {
    if (items.isEmpty) return 0;
    
    // Group by month
    final monthlyTotals = groupByMonth(items, getDateString, getAmount);
    
    // Calculate average
    final totalAmount = monthlyTotals.values.fold(0.0, (sum, amount) => sum + amount);
    return totalAmount / monthlyTotals.length;
  }
  
  /// Analyze spending trends - returns percent change from previous period
  static double analyzeTrend(List<double> values) {
    if (values.length < 2) return 0;
    
    final current = values.last;
    final previous = values[values.length - 2];
    
    if (previous == 0) return current > 0 ? 100 : 0;
    
    return ((current - previous) / previous) * 100;
  }
  
  /// Calculate budget utilization percentage
  static double calculateBudgetUtilization(double spent, double budgetLimit) {
    if (budgetLimit <= 0) return 0;
    return (spent / budgetLimit) * 100;
  }
  
  /// Predict future expenses based on historical data using simple linear regression
  static List<double> predictFutureExpenses(List<double> historicalExpenses, int monthsToPredict) {
    if (historicalExpenses.length < 2) {
      // Not enough data for prediction, repeat the last value
      return List.filled(
        monthsToPredict, 
        historicalExpenses.isNotEmpty ? historicalExpenses.last : 0
      );
    }
    
    // Simple linear regression
    // y = mx + b
    // Where y is the expense amount, x is the time period
    
    // Calculate x values (time periods) starting from 0
    final List<double> xValues = List.generate(
      historicalExpenses.length, 
      (index) => index.toDouble()
    );
    
    // Calculate means
    final double xMean = xValues.reduce((a, b) => a + b) / xValues.length;
    final double yMean = historicalExpenses.reduce((a, b) => a + b) / historicalExpenses.length;
    
    // Calculate slope (m)
    double numerator = 0;
    double denominator = 0;
    
    for (int i = 0; i < historicalExpenses.length; i++) {
      numerator += (xValues[i] - xMean) * (historicalExpenses[i] - yMean);
      denominator += pow(xValues[i] - xMean, 2);
    }
    
    final double slope = denominator != 0 ? numerator / denominator : 0;
    
    // Calculate y-intercept (b)
    final double intercept = yMean - (slope * xMean);
    
    // Predict future values
    final List<double> predictions = [];
    
    for (int i = 0; i < monthsToPredict; i++) {
      final x = xValues.length + i.toDouble();
      final prediction = max(0, (slope * x) + intercept); // Ensure no negative predictions
      predictions.add(prediction);
    }
    
    return predictions;
  }
  
  /// Generate random color for charts
  static String generateRandomColor() {
    final random = Random();
    final r = random.nextInt(256);
    final g = random.nextInt(256);
    final b = random.nextInt(256);
    
    // Convert to hex string
    final hexColor = '#${r.toRadixString(16).padLeft(2, '0')}'
                    '${g.toRadixString(16).padLeft(2, '0')}'
                    '${b.toRadixString(16).padLeft(2, '0')}';
    
    return hexColor;
  }
  
  /// Calculate risk indicator based on spending vs. income
  static Map<String, dynamic> calculateFinancialRisk(List<Income> incomes, List<Expense> expenses) {
    final totalIncome = calculateTotalIncome(incomes);
    final totalExpenses = calculateTotalExpenses(expenses);
    
    if (totalIncome <= 0) {
      return {
        'risk_level': 'high',
        'risk_score': 100,
        'message': 'No income recorded',
      };
    }
    
    final expenseRatio = totalExpenses / totalIncome * 100;
    
    String riskLevel;
    String message;
    int riskScore;
    
    if (expenseRatio < 50) {
      riskLevel = 'low';
      riskScore = 25;
      message = 'Your expenses are well below your income';
    } else if (expenseRatio < 75) {
      riskLevel = 'moderate-low';
      riskScore = 50;
      message = 'Your expenses are manageable compared to your income';
    } else if (expenseRatio < 90) {
      riskLevel = 'moderate';
      riskScore = 65;
      message = 'Your expenses are approaching your income';
    } else if (expenseRatio < 100) {
      riskLevel = 'moderate-high';
      riskScore = 80;
      message = 'Your expenses are very close to your income';
    } else {
      riskLevel = 'high';
      riskScore = 100;
      message = 'Your expenses exceed your income';
    }
    
    return {
      'risk_level': riskLevel,
      'risk_score': riskScore,
      'expense_ratio': expenseRatio,
      'message': message,
    };
  }
}