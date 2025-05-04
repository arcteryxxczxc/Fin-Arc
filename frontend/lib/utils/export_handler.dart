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
import 'error_handler.dart';

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
      final result = await _reportService.exportReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (!result['success']) {
        return false;
      }
      
      // Get response data
      final Uint8List data = result['data'];
      final String contentType = result['content-type'] ?? 'application/json';
      String filename = result['filename'] ?? '$reportName.json';
      
      // Determine the file extension based on content type
      if (!filename.contains('.')) {
        if (contentType.contains('csv')) {
          filename = '$filename.csv';
        } else if (contentType.contains('excel') || contentType.contains('spreadsheet')) {
          filename = '$filename.xlsx';
        } else if (contentType.contains('pdf')) {
          filename = '$filename.pdf';
        } else {
          filename = '$filename.json';
        }
      }
      
      // Save and share the file
      return await _saveAndShareFile(data, filename, contentType);
    } catch (e) {
      print('Error exporting report: $e');
      return false;
    }
  }
  
  /// Export data to CSV format
  Future<bool> exportToCsv(List<Map<String, dynamic>> data, String filename) async {
    try {
      // Convert data to CSV
      final List<List<dynamic>> csvData = [];
      
      // Add header row if data is not empty
      if (data.isNotEmpty) {
        csvData.add(data.first.keys.toList());
      }
      
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
        // For web, download directly using data URI
        return false; // Web download not implemented yet
      } else {
        // Get temporary directory for file storage
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$filename';
        
        // Write data to file
        final file = File(filePath);
        await file.writeAsBytes(data);
        
        // Share the file
        final result = await Share.shareXFiles(
          [XFile(filePath, mimeType: contentType)],
          subject: 'Sharing $filename',
        );
        
        return result.status == ShareResultStatus.success;
      }
    } catch (e) {
      print('Error saving or sharing file: $e');
      return false;
    }
  }
}