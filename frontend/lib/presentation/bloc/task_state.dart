import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';

enum TaskStatusEnum { initial, loading, loaded, error }

class TaskState extends Equatable {
  final TaskStatusEnum status;
  final List<Task> tasks;
  final List<Task> filteredTasks;
  final String errorMessage;
  final String searchQuery;
  final String? filterStatus;
  
  // For the UI loading state of a specific operation (Create/Update)
  final bool isSubmitting;
  final String? submitError;

  const TaskState({
    this.status = TaskStatusEnum.initial,
    this.tasks = const [],
    this.filteredTasks = const [],
    this.errorMessage = '',
    this.searchQuery = '',
    this.filterStatus,
    this.isSubmitting = false,
    this.submitError,
  });

  TaskState copyWith({
    TaskStatusEnum? status,
    List<Task>? tasks,
    List<Task>? filteredTasks,
    String? errorMessage,
    String? searchQuery,
    String? filterStatus,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        filteredTasks,
        errorMessage,
        searchQuery,
        filterStatus,
        isSubmitting,
        submitError,
      ];
}
