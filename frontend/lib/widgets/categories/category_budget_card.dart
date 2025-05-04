import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';

/// A widget for displaying and editing a category's budget limit
class CategoryBudgetCard extends StatelessWidget {
  final Category category;
  final Function(double) onBudgetChanged;

  const CategoryBudgetCard({
    super.key,
    required this.category,
    required this.onBudgetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    // Parse color from hex string
    final categoryColor = Color(int.parse(category.colorCode.substring(1, 7), radix: 16) + 0xFF000000);
    
    // Calculate spending percentage and status
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
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header with icon and name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      category.icon != null 
                        ? IconData(int.parse(category.icon!), fontFamily: 'MaterialIcons')
                        : Icons.category,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 16),
            
            // Budget progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Spent: ${currencyFormatter.format(spent)}'),
                Text(
                  '${percentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage / 100 > 1 ? 1 : percentage / 100,
              minHeight: 8,
              backgroundColor: theme.dividerColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 16),
            
            // Budget input and remaining amount
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: budgetLimit > 0 ? budgetLimit.toString() : '',
                    decoration: InputDecoration(
                      labelText: 'Budget Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final newBudget = double.tryParse(value) ?? 0;
                      onBudgetChanged(newBudget);
                    },
                  ),
                ),
                if (budgetLimit > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Remaining: ${currencyFormatter.format(budgetLimit - spent)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: budgetLimit - spent >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}