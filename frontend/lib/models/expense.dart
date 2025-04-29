class Expense {
  final int id;
  final double amount;
  final String formattedAmount;
  final String? description;
  final String date;
  final String? time;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String? paymentMethod;
  final String? location;
  final bool hasReceipt;
  final String? receiptPath;
  final bool isRecurring;
  final String? recurringType;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  Expense({
    required this.id,
    required this.amount,
    required this.formattedAmount,
    this.description,
    required this.date,
    this.time,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.paymentMethod,
    this.location,
    required this.hasReceipt,
    this.receiptPath,
    required this.isRecurring,
    this.recurringType,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: json['amount'].toDouble(),
      formattedAmount: json['formatted_amount'] ?? json['amount'].toString(),
      description: json['description'],
      date: json['date'],
      time: json['time'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      categoryColor: json['category_color'],
      paymentMethod: json['payment_method'],
      location: json['location'],
      hasReceipt: json['has_receipt'] ?? false,
      receiptPath: json['receipt_path'],
      isRecurring: json['is_recurring'] ?? false,
      recurringType: json['recurring_type'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  // Convert Expense to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'formatted_amount': formattedAmount,
      'description': description,
      'date': date,
      'time': time,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'payment_method': paymentMethod,
      'location': location,
      'has_receipt': hasReceipt,
      'receipt_path': receiptPath,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create a copy of this Expense with some fields updated
  Expense copyWith({
    int? id,
    double? amount,
    String? formattedAmount,
    String? description,
    String? date,
    String? time,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    String? paymentMethod,
    String? location,
    bool? hasReceipt,
    String? receiptPath,
    bool? isRecurring,
    String? recurringType,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      formattedAmount: formattedAmount ?? this.formattedAmount,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      location: location ?? this.location,
      hasReceipt: hasReceipt ?? this.hasReceipt,
      receiptPath: receiptPath ?? this.receiptPath,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}