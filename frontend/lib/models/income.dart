class Income {
  final int id;
  final double amount;
  final String formattedAmount;
  final String source;
  final String? description;
  final String date;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final bool isRecurring;
  final String? recurringType;
  final int? recurringDay;
  final bool isTaxable;
  final double? taxRate;
  final double afterTaxAmount;
  final String? createdAt;
  final String? updatedAt;

  Income({
    required this.id,
    required this.amount,
    required this.formattedAmount,
    required this.source,
    this.description,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.isRecurring,
    this.recurringType,
    this.recurringDay,
    required this.isTaxable,
    this.taxRate,
    required this.afterTaxAmount,
    this.createdAt,
    this.updatedAt,
  });

  // Create Income from JSON with safe type conversion
  factory Income.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double values
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return 0.0;
        }
      }
      return 0.0;
    }
    
    // Default date to today if missing
    String parseDate(dynamic value) {
      if (value == null) return DateTime.now().toIso8601String().split('T')[0];
      if (value is String) return value;
      return DateTime.now().toIso8601String().split('T')[0];
    }
    
    // Parse integer values
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return Income(
      id: json['id'] ?? 0,
      amount: parseDouble(json['amount']),
      formattedAmount: json['formatted_amount'] ?? parseDouble(json['amount']).toString(),
      source: json['source'] ?? 'Unknown Source',
      description: json['description'],
      date: parseDate(json['date']),
      categoryId: parseInt(json['category_id']),
      categoryName: json['category_name'],
      categoryColor: json['category_color'],
      isRecurring: json['is_recurring'] ?? false,
      recurringType: json['recurring_type'],
      recurringDay: parseInt(json['recurring_day']),
      isTaxable: json['is_taxable'] ?? false,
      taxRate: parseDouble(json['tax_rate']),
      afterTaxAmount: parseDouble(json['after_tax_amount']) != 0.0 
          ? parseDouble(json['after_tax_amount']) 
          : parseDouble(json['amount']),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Convert Income to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'formatted_amount': formattedAmount,
      'source': source,
      'description': description,
      'date': date,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'recurring_day': recurringDay,
      'is_taxable': isTaxable,
      'tax_rate': taxRate,
      'after_tax_amount': afterTaxAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create a copy of this Income with some fields updated
  Income copyWith({
    int? id,
    double? amount,
    String? formattedAmount,
    String? source,
    String? description,
    String? date,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    bool? isRecurring,
    String? recurringType,
    int? recurringDay,
    bool? isTaxable,
    double? taxRate,
    double? afterTaxAmount,
    String? createdAt,
    String? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      formattedAmount: formattedAmount ?? this.formattedAmount,
      source: source ?? this.source,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      recurringDay: recurringDay ?? this.recurringDay,
      isTaxable: isTaxable ?? this.isTaxable,
      taxRate: taxRate ?? this.taxRate,
      afterTaxAmount: afterTaxAmount ?? this.afterTaxAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}