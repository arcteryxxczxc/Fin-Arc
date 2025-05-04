// lib/utils/export_handler.dart
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:cross_file/cross_file.dart';
import '../services/report_service.dart';

/// A utility class for handling the export of reports and data
class ExportHandler {
  final ReportService _reportService = ReportService();
  
  /// Export a report to a file and share it
  Future<bool> exportReport({
    required String reportType,
    required String reportName,
    String? startDate,
    String? endDate,
  }) async {
    try {
      print('Starting export for $reportType from $startDate to $endDate');
      
      final result = await _reportService.exportReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (!result['success']) {
        print('Export API request failed: ${result['message']}');
        return false;
      }
      
      // Get response data
      if (!result.containsKey('data')) {
        print('No data in export response');
        return false;
      }
      
      final data = result['data'];
      if (data is! Uint8List) {
        print('Export data is not Uint8List: ${data.runtimeType}');
        return false;
      }
      
      final Uint8List bytes = data;
      if (bytes.isEmpty) {
        print('Export data is empty');
        return false;
      }
      
      final String contentType = result['content-type'] ?? 'application/octet-stream';
      String filename = result['filename'] ?? '$reportName.csv';
      
      // Determine the file extension based on content type if not already in filename
      if (!filename.contains('.')) {
        if (contentType.contains('csv')) {
          filename = '$filename.csv';
        } else if (contentType.contains('excel') || contentType.contains('spreadsheet')) {
          filename = '$filename.xlsx';
        } else if (contentType.contains('pdf')) {
          filename = '$filename.pdf';
        } else if (contentType.contains('json')) {
          filename = '$filename.json';
        } else {
          // Default to CSV
          filename = '$filename.csv';
        }
      }
      
      print('Export successful, saving file: $filename (${bytes.length} bytes)');
      
      // Save and share the file
      return await _saveAndShareFile(bytes, filename, contentType);
    } catch (e) {
      print('Error in export process: $e');
      return false;
    }
  }
  
  /// Export data to CSV format
  Future<bool> exportToCsv(List<Map<String, dynamic>> data, String filename) async {
    try {
      if (data.isEmpty) {
        print('No data to export to CSV');
        return false;
      }
      
      // Convert data to CSV
      final List<List<dynamic>> csvData = [];
      
      // Add header row
      csvData.add(data.first.keys.toList());
      
      // Add data rows
      for (var item in data) {
        csvData.add(item.values.toList());
      }
      
      // Convert to CSV string
      final String csv = const ListToCsvConverter().convert(csvData);
      
      // Convert to bytes
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
      
      // Ensure filename has .csv extension
      if (!filename.toLowerCase().endsWith('.csv')) {
        filename = '$filename.csv';
      }
      
      // Save and share the file
      return await _saveAndShareFile(bytes, filename, 'text/csv');
    } catch (e) {
      print('Error exporting to CSV: $e');
      return false;
    }
  }
  
  /// Save data to a temporary file and share it
  Future<bool> _saveAndShareFile(Uint8List data, String filename, String contentType) async {
    try {
      if (kIsWeb) {
        // Web platform not fully supported yet
        print('Web platform export not fully implemented');
        return false;
      } else {
        // Get temporary directory for file storage
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$filename';
        
        print('Saving file to: $filePath');
        
        // Write data to file
        final file = File(filePath);
        await file.writeAsBytes(data);
        
        if (!await file.exists()) {
          print('Failed to create file: $filePath');
          return false;
        }
        
        print('File created successfully, size: ${await file.length()} bytes');
        
        // Share the file
        final xFile = XFile(filePath, mimeType: contentType);
        final result = await Share.shareXFiles(
          [xFile],
          subject: 'Fin-Arc: $filename',
          text: 'Sharing $filename from Fin-Arc',
        );
        
        print('Share result status: ${result.status}');
        return result.status == ShareResultStatus.success;
      }
    } catch (e) {
      print('Error saving or sharing file: $e');
      return false;
    }
  }
  
  /// Generate a mock export file for testing (when API isn't working)
  Future<bool> generateMockExport(String reportType, String reportName) async {
    try {
      print('Generating mock export for $reportType');
      
      // Create mock CSV data based on report type
      List<List<dynamic>> csvData = [];
      
      switch (reportType) {
        case 'expenses':
          csvData = [
            ['Date', 'Description', 'Category', 'Amount'],
            ['2023-05-01', 'Groceries', 'Food', 125.50],
            ['2023-05-03', 'Gas', 'Transportation', 45.75],
            ['2023-05-10', 'Internet Bill', 'Utilities', 65.00],
            ['2023-05-15', 'Dinner', 'Food', 85.25],
            ['2023-05-20', 'Movie Tickets', 'Entertainment', 32.00],
          ];
          break;
        case 'income':
          csvData = [
            ['Date', 'Source', 'Description', 'Amount'],
            ['2023-05-01', 'Salary', 'Monthly Salary', 3500.00],
            ['2023-05-15', 'Freelance', 'Website Project', 750.00],
            ['2023-05-28', 'Dividend', 'Investment Return', 120.50],
          ];
          break;
        case 'monthly':
          csvData = [
            ['Category', 'Budget', 'Spent', 'Remaining', 'Percentage'],
            ['Food', 500.00, 350.75, 149.25, 70.15],
            ['Transportation', 200.00, 185.50, 14.50, 92.75],
            ['Utilities', 300.00, 265.00, 35.00, 88.33],
            ['Entertainment', 150.00, 132.00, 18.00, 88.00],
            ['Shopping', 400.00, 375.25, 24.75, 93.81],
          ];
          break;
        case 'annual':
          csvData = [
            ['Month', 'Income', 'Expenses', 'Savings', 'Savings Rate'],
            ['January', 4250.00, 3450.75, 799.25, 18.80],
            ['February', 4250.00, 3200.50, 1049.50, 24.69],
            ['March', 4500.00, 3750.25, 749.75, 16.66],
            ['April', 4250.00, 3500.00, 750.00, 17.64],
            ['May', 4370.50, 3650.25, 720.25, 16.48],
          ];
          break;
        default:
          csvData = [
            ['Type', 'Date', 'Description', 'Amount'],
            ['Data for report type not available', '', '', 0],
          ];
      }
      
      // Convert to CSV string
      final String csv = const ListToCsvConverter().convert(csvData);
      
      // Convert to bytes
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
      
      // Create filename
      final filename = '${reportName.replaceAll(' ', '_').toLowerCase()}.csv';
      
      // Save and share the file
      return await _saveAndShareFile(bytes, filename, 'text/csv');
    } catch (e) {
      print('Error generating mock export: $e');
      return false;
    }
  }
}