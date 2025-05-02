class Category {
  final int id;
  final String name;
  final String? description;
  final String colorCode;
  final String? icon;
  final double? budgetLimit;
  final int budgetStartDay;
  final bool isIncome;
  final bool isActive;
  final double? currentSpending;
  final double? budgetPercentage;
  final String? budgetStatus;
  
  Category({
    required this.id,
    required this.name,
    this.description,
    required this.colorCode,
    this.icon,
    this.budgetLimit,
    this.budgetStartDay = 1,
    required this.isIncome,
    required this.isActive,
    this.currentSpending,
    this.budgetPercentage,
    this.budgetStatus,
  });
  
  // Create Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      colorCode: json['color'] ?? json['color_code'] ?? '#757575',
      icon: json['icon'],
      budgetLimit: json['budget']?.toDouble(),
      budgetStartDay: json['budget_start_day'] ?? 1,
      isIncome: json['is_income'] ?? false,
      isActive: json['is_active'] ?? true,
      currentSpending: json['current_spending']?.toDouble(),
      budgetPercentage: json['budget_percentage']?.toDouble(),
      budgetStatus: json['budget_status'],
    );
  }
  
  // Convert Category to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_code': colorCode,
      'icon': icon,
      'budget_limit': budgetLimit,
      'budget_start_day': budgetStartDay,
      'is_income': isIncome,
      'is_active': isActive,
      'current_spending': currentSpending,
      'budget_percentage': budgetPercentage,
      'budget_status': budgetStatus,
    };
  }
  
  // Create a copy of this Category with some fields updated
  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? colorCode,
    String? icon,
    double? budgetLimit,
    int? budgetStartDay,
    bool? isIncome,
    bool? isActive,
    double? currentSpending,
    double? budgetPercentage,
    String? budgetStatus,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorCode: colorCode ?? this.colorCode,
      icon: icon ?? this.icon,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      budgetStartDay: budgetStartDay ?? this.budgetStartDay,
      isIncome: isIncome ?? this.isIncome,
      isActive: isActive ?? this.isActive,
      currentSpending: currentSpending ?? this.currentSpending,
      budgetPercentage: budgetPercentage ?? this.budgetPercentage,
      budgetStatus: budgetStatus ?? this.budgetStatus,
    );
  }
}