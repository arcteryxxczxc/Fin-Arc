// budget.dart
class Budget {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final double amount;
  final double spent;
  final double remaining;
  final double percentage;
  final String period; // 'monthly', 'weekly', etc.
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'good', 'warning', 'over'
  
  Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.amount,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.status,
  });
  
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryColor: json['category_color'],
      amount: (json['amount'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      period: json['period'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'amount': amount,
      'spent': spent,
      'remaining': remaining,
      'percentage': percentage,
      'period': period,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
    };
  }
}