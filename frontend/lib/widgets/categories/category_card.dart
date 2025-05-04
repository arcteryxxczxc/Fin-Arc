import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';

/// A widget that displays a category card with details and actions
class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showBudget;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.showBudget = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    // Parse color from hex string
    final categoryColor = Color(int.parse(category.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header with icon and name
              Row(
                children: [
                  // Category icon with color
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        category.icon != null 
                          ? IconData(int.parse(category.icon!), fontFamily: 'MaterialIcons')
                          : category.isIncome ? Icons.account_balance : Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Category name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!category.isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Inactive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (category.description != null && category.description!.isNotEmpty)
                          Text(
                            category.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Budget progress (only for expense categories with a budget)
              if (showBudget && !category.isIncome && category.budgetLimit != null && category.budgetLimit! > 0) ...[
                const SizedBox(height: 16),
                _buildBudgetProgress(category, theme, currencyFormatter),
              ],
              
              const SizedBox(height: 8),
              
              // Actions row (Edit and Delete)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Builds the budget progress section for expense categories
  Widget _buildBudgetProgress(Category category, ThemeData theme, NumberFormat currencyFormatter) {
    final budgetLimit = category.budgetLimit ?? 0;
    final spent = category.currentSpending ?? 0;
    final percentage = category.budgetPercentage ?? 0;
    
    // Determine color based on percentage
    Color progressColor;
    if (percentage >= 100) {
      progressColor = Colors.red;
    } else if (percentage >= 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget: ${currencyFormatter.format(budgetLimit)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100 > 1 ? 1 : percentage / 100,
          minHeight: 6,
          backgroundColor: theme.dividerColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spent: ${currencyFormatter.format(spent)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Remaining: ${currencyFormatter.format(budgetLimit - spent)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: budgetLimit - spent >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}