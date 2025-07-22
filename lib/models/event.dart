import 'category.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final Category? category;
  final String? recurrenceRule;
  final int? reminderMinutes;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    this.category,
    this.recurrenceRule,
    this.reminderMinutes,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        isAllDay: json['isAllDay'] == 1,
        category: json['category'] != null && json['category'] is Map<String, dynamic>
            ? Category.fromJson(json['category'])
            : null,
        recurrenceRule: json['recurrenceRule'],
        reminderMinutes: json['reminderMinutes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'isAllDay': isAllDay ? 1 : 0,
        'categoryId': category?.id,
        'recurrenceRule': recurrenceRule,
        'reminderMinutes': reminderMinutes,
      };
}
