// notification.dart
class Notification {
  final int id;
  final String title;
  final String message;
  final String type; // 'budget', 'expense', 'reminder', etc.
  final DateTime createdAt;
  final bool isRead;
  final String? linkType; // Where to navigate when tapped
  final int? linkId; // ID of related entity
  
  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.linkType,
    this.linkId,
  });
  
  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      linkType: json['link_type'],
      linkId: json['link_id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'link_type': linkType,
      'link_id': linkId,
    };
  }
}