import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class CreateTask extends TaskEvent {
  final Task task;

  const CreateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TaskEvent {
  final int id;
  final Task task;

  const UpdateTask(this.id, this.task);

  @override
  List<Object?> get props => [id, task];
}

class DeleteTask extends TaskEvent {
  final int id;

  const DeleteTask(this.id);

  @override
  List<Object?> get props => [id];
}

class FilterTasks extends TaskEvent {
  final String? query;
  final String? status;

  const FilterTasks({this.query, this.status});

  @override
  List<Object?> get props => [query, status];
}
