// lib/widgets/common/input_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? currencySymbol;
  final bool isRequired;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  
  const CurrencyInputField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint = 'Enter amount',
    this.currencySymbol,
    this.isRequired = true,
    this.validator,
    this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final sym = currencySymbol ?? '\$';
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            sym,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: validator ?? (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter an amount';
        }
        if (value != null && value.isNotEmpty) {
          try {
            double.parse(value);
          } catch (e) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}

class DateInputField extends StatelessWidget {
  final DateTime value;
  final String label;
  final Function(DateTime) onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  
  const DateInputField({
    Key? key,
    required this.value,
    required this.label,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime.now().add(Duration(days: 365)),
        );
        if (picked != null && picked != value) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          DateFormat('MMM d, yyyy').format(value),
        ),
      ),
    );
  }
}

class DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? Function(T?)? validator;
  final Widget? icon;
  
  const DropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final Function(String)? onChanged;
  final Function()? onSubmitted;
  final Function()? onClear;
  
  const SearchInputField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) onClear!();
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
      onSubmitted: (value) {
        if (onSubmitted != null) onSubmitted!();
      },
    );
  }
}