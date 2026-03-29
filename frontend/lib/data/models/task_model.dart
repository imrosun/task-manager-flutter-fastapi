import 'package:equatable/equatable.dart';

enum TaskStatus {
  todo("To-Do"),
  inProgress("In-Progress"),
  done("Done");

  final String value;
  const TaskStatus(this.value);

  factory TaskStatus.fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

class Task extends Equatable {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? blockedById;

  const Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.todo,
    this.blockedById,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      status: TaskStatus.fromValue(json['status']),
      blockedById: json['blocked_by_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate.toIso8601String(),
      'status': status.value,
      if (blockedById != null) 'blocked_by_id': blockedById,
    };
  }
  
  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    int? blockedById,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById ?? this.blockedById,
    );
  }

  @override
  List<Object?> get props => [id, title, description, dueDate, status, blockedById];
}
