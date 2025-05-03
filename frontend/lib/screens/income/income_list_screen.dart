import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/income_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/income.dart';
import '../../models/category.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';
import '../../widgets/common/drawer.dart';
import '../../routes/route_names.dart';
import 'income_detail_screen.dart';
import 'add_income_screen.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  _IncomeListScreenState createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _searchQuery;
  String _sortBy = 'date'; // 'date', 'amount', 'source'
  bool _sortAscending = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set default date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    
    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIncomes();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreIncomes();
    }
  }
  
  Future<void> _loadIncomes() async {
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    
    // Convert category name to ID if selected
    int? categoryId;
    if (_selectedCategory != null) {
      final categories = Provider.of<CategoryProvider>(context, listen: false).categories;
      final category = categories.firstWhere(
        (c) => c.name == _selectedCategory,
        orElse: () => Category(
          id: -1, 
          name: 'Uncategorized', 
          colorCode: '#757575', 
          isIncome: true, 
          isActive: true
        ),
      );
      categoryId = category.id;
    }
    
    // Format dates
    String? startDateStr, endDateStr;
    if (_startDate != null) {
      startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    }
    if (_endDate != null) {
      endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);
    }
    
    await incomeProvider.fetchIncomes(
      refresh: true,
      categoryId: categoryId,
      startDate: startDateStr,
      endDate: endDateStr,
      search: _searchQuery,
    );
    
    // Apply sorting
    _sortIncomes();
  }
  
  Future<void> _loadMoreIncomes() async {
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    
    // Only load more if there are more pages
    if (incomeProvider.hasMorePages) {
      await incomeProvider.loadMoreIncomes();
      
      // Apply sorting to the new data
      _sortIncomes();
    }
  }
  
  void _sortIncomes() {
    final incomeProvider = Provider.of<IncomeProvider>(context, listen: false);
    final incomes = List<Income>.from(incomeProvider.incomes);
    
    switch (_sortBy) {
      case 'date':
        incomes.sort((a, b) {
          final dateA = DateTime.parse(a.date);
          final dateB = DateTime.parse(b.date);
          return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
        });
        break;
      case 'amount':
        incomes.sort((a, b) {
          return _sortAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount);
        });
        break;
      case 'source':
        incomes.sort((a, b) {
          return _sortAscending ? a.source.compareTo(b.source) : b.source.compareTo(a.source);
        });
        break;
    }
    
    setState(() {}); // Refresh UI with sorted data
  }
  
  void _showFilterDialog() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final categories = categoryProvider.incomeCategories;
    
    // Create a temporary copy of the current filters
    String? tempCategory = _selectedCategory;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Incomes'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category filter
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  value: tempCategory,
                  onChanged: (value) {
                    setState(() {
                      tempCategory = value;
                    });
                  },
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((category) => DropdownMenuItem<String?>(
                      value: category.name,
                      child: Text(category.name),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Date range filter
                const Text(
                  'Date Range',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              tempStartDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelText: 'From',
                          ),
                          child: Text(
                            tempStartDate != null
                                ? DateFormat('MM/dd/yyyy').format(tempStartDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              tempEndDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelText: 'To',
                          ),
                          child: Text(
                            tempEndDate != null
                                ? DateFormat('MM/dd/yyyy').format(tempEndDate!)
                                : 'Select Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quick date range buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickDateRangeButton(
                      label: 'This Month',
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDate = DateTime(now.year, now.month, 1);
                          tempEndDate = DateTime(now.year, now.month + 1, 0);
                        });
                      },
                    ),
                    _quickDateRangeButton(
                      label: 'Last Month',
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDate = DateTime(now.year, now.month - 1, 1);
                          tempEndDate = DateTime(now.year, now.month, 0);
                        });
                      },
                    ),
                    _quickDateRangeButton(
                      label: 'This Year',
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDate = DateTime(now.year, 1, 1);
                          tempEndDate = DateTime(now.year, 12, 31);
                        });
                      },
                    ),
                    _quickDateRangeButton(
                      label: 'Clear',
                      onTap: () {
                        setState(() {
                          tempStartDate = null;
                          tempEndDate = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = tempCategory;
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                });
                Navigator.of(ctx).pop();
                _loadIncomes();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _quickDateRangeButton({required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }
  
  void _showSortDialog() {
    final options = {
      'date': 'Date',
      'amount': 'Amount',
      'source': 'Source',
    };
    
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sort By'),
        children: options.entries.map((entry) {
          final isSelected = _sortBy == entry.key;
          
          return ListTile(
            title: Text(entry.value),
            trailing: isSelected
                ? Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            selected: isSelected,
            onTap: () {
              setState(() {
                if (_sortBy == entry.key) {
                  // Toggle direction if the same field
                  _sortAscending = !_sortAscending;
                } else {
                  // Reset direction for new field
                  _sortBy = entry.key;
                  _sortAscending = entry.key != 'date'; // Default: date DESC, others ASC
                }
              });
              Navigator.of(ctx).pop();
              _sortIncomes();
            },
          );
        }).toList(),
      ),
    );
  }
  
  void _showSearchBar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Incomes'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter search term',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _searchQuery = value.isNotEmpty ? value : null;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _loadIncomes();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incomeProvider = Provider.of<IncomeProvider>(context);
    final incomes = incomeProvider.incomes;
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchBar,
            tooltip: 'Search incomes',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter incomes',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: 'Sort incomes',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: RouteNames.incomeList),
      body: Column(
        children: [
          // Active filters display
          if (_selectedCategory != null || _startDate != null || _endDate != null || _searchQuery != null) 
            _buildActiveFilters(),
          
          // Income list
          Expanded(
            child: _buildIncomeList(theme, incomeProvider, incomes, currencyFormatter),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddIncomeScreen(),
            ),
          ).then((_) => _loadIncomes());
        },
        tooltip: 'Add income',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Filters:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedCategory != null)
                _buildFilterChip(
                  label: 'Category: $_selectedCategory',
                  onRemove: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                    _loadIncomes();
                  },
                ),
              if (_startDate != null && _endDate != null)
                _buildFilterChip(
                  label: 'Date: ${DateFormat('MM/dd/yyyy').format(_startDate!)} - ${DateFormat('MM/dd/yyyy').format(_endDate!)}',
                  onRemove: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadIncomes();
                  },
                ),
              if (_searchQuery != null)
                _buildFilterChip(
                  label: 'Search: $_searchQuery',
                  onRemove: () {
                    setState(() {
                      _searchQuery = null;
                    });
                    _loadIncomes();
                  },
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _startDate = null;
                    _endDate = null;
                    _searchQuery = null;
                  });
                  _loadIncomes();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIncomeList(
    ThemeData theme, 
    IncomeProvider incomeProvider, 
    List<Income> incomes,
    NumberFormat currencyFormatter,
  ) {
    if (incomeProvider.isLoading && incomes.isEmpty) {
      return const LoadingIndicator(message: 'Loading incomes...');
    }
    
    if (incomeProvider.error != null && incomes.isEmpty) {
      return ErrorDisplay(
        error: incomeProvider.error!,
        onRetry: _loadIncomes,
      );
    }
    
    if (incomes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No income entries found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first income or change filters',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadIncomes,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: incomes.length + (incomeProvider.hasMorePages ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == incomes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final income = incomes[index];
          
          // Get category color if available
          Color categoryColor = theme.primaryColor;
          if (income.categoryColor != null && income.categoryColor!.isNotEmpty) {
            categoryColor = Color(int.parse(income.categoryColor!.substring(1, 7), radix: 16) + 0xFF000000);
          }
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            leading: CircleAvatar(
              backgroundColor: income.categoryId != null ? categoryColor.withOpacity(0.2) : Colors.green[100],
              child: Icon(
                Icons.arrow_upward,
                color: income.categoryId != null ? categoryColor : Colors.green,
              ),
            ),
            title: Text(
              income.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.parse(income.date)),
                ),
                if (income.categoryName != null)
                  Text(
                    income.categoryName!,
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              income.formattedAmount,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => IncomeDetailScreen(incomeId: income.id),
                ),
              ).then((_) => _loadIncomes());
            },
          );
        },
      ),
    );
  }
}