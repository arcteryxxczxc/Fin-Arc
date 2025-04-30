// report.dart
class Report {
  final String id;
  final String title;
  final String type; // 'monthly', 'annual', 'category', etc.
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final DateTime generatedAt;
  
  Report({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.generatedAt,
  });
  
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      data: json['data'],
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'data': data,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}