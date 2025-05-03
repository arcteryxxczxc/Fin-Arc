class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? createdAt;
  final String? lastLogin;
  final bool isActive;
  final bool isAdmin;
  final UserStats? stats;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.isAdmin = false,
    this.stats,
  });

  // Create User from JSON with safe type conversion
  factory User.fromJson(Map<String, dynamic> json) {
    // Handle stats if available
    UserStats? stats;
    if (json['stats'] != null && json['stats'] is Map<String, dynamic>) {
      try {
        stats = UserStats.fromJson(json['stats'] as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing user stats: $e');
      }
    }
    
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      createdAt: json['created_at'],
      lastLogin: json['last_login'],
      isActive: json['is_active'] ?? true,
      isAdmin: json['is_admin'] ?? false,
      stats: stats,
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'created_at': createdAt,
      'last_login': lastLogin,
      'is_active': isActive,
      'is_admin': isAdmin,
      'stats': stats?.toJson(),
    };
  }

  // Get user's full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return username;
    }
  }
  
  // Get user's initials for avatar
  String get initials {
    if (firstName != null && firstName!.isNotEmpty && 
        lastName != null && lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    } else if (lastName != null && lastName!.isNotEmpty) {
      return lastName![0].toUpperCase();
    } else if (username.isNotEmpty) {
      return username[0].toUpperCase();
    } else {
      return 'U'; // Default initial if all else fails
    }
  }
  
  // Create a copy of this User with some fields updated
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? createdAt,
    String? lastLogin,
    bool? isActive,
    bool? isAdmin,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      isAdmin: isAdmin ?? this.isAdmin,
      stats: stats ?? this.stats,
    );
  }
}

/// User financial statistics 
class UserStats {
  final double? totalExpensesCurrentMonth;
  final double? totalIncomeCurrentMonth;
  final double? currentMonthBalance;
  final double? savingsRate;
  
  UserStats({
    this.totalExpensesCurrentMonth,
    this.totalIncomeCurrentMonth,
    this.currentMonthBalance,
    this.savingsRate,
  });
  
  // Create UserStats from JSON with safe type conversion
  factory UserStats.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
    
    return UserStats(
      totalExpensesCurrentMonth: parseDouble(json['total_expenses_current_month']),
      totalIncomeCurrentMonth: parseDouble(json['total_income_current_month']),
      currentMonthBalance: parseDouble(json['current_month_balance']),
      savingsRate: parseDouble(json['savings_rate']),
    );
  }
  
  // Convert UserStats to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_expenses_current_month': totalExpensesCurrentMonth,
      'total_income_current_month': totalIncomeCurrentMonth,
      'current_month_balance': currentMonthBalance,
      'savings_rate': savingsRate,
    };
  }
}