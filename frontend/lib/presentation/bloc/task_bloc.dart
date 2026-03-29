import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/models/task_model.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final TaskRepository taskRepository;

  TaskBloc({required this.taskRepository}) : super(const TaskState()) {
    on<LoadTasks>(_onLoadTasks);
    on<CreateTask>(_onCreateTask);
    on<UpdateTask>(_onUpdateTask);
    on<DeleteTask>(_onDeleteTask);
    
    // Applying debounce to FilterTasks
    on<FilterTasks>(
      _onFilterTasks,
      transformer: (events, mapper) {
        return events
            .debounceTime(const Duration(milliseconds: 300))
            .switchMap(mapper);
      },
    );
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(state.copyWith(status: TaskStatusEnum.loading));
    try {
      final tasks = await taskRepository.getTasks();
      emit(state.copyWith(
        status: TaskStatusEnum.loaded,
        tasks: tasks,
        filteredTasks: _applyFilters(tasks, state.searchQuery, state.filterStatus),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatusEnum.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateTask(CreateTask event, Emitter<TaskState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final newTask = await taskRepository.createTask(event.task);
      final updatedTasks = List<Task>.from(state.tasks)..add(newTask);
      emit(state.copyWith(
        isSubmitting: false,
        tasks: updatedTasks,
        filteredTasks: _applyFilters(updatedTasks, state.searchQuery, state.filterStatus),
      ));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }

  Future<void> _onUpdateTask(UpdateTask event, Emitter<TaskState> emit) async {
    emit(state.copyWith(isSubmitting: true, clearSubmitError: true));
    try {
      final updatedTask = await taskRepository.updateTask(event.id, event.task);
      final updatedTasks = state.tasks.map((t) => t.id == event.id ? updatedTask : t).toList();
      emit(state.copyWith(
        isSubmitting: false,
        tasks: updatedTasks,
        filteredTasks: _applyFilters(updatedTasks, state.searchQuery, state.filterStatus),
      ));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }

  Future<void> _onDeleteTask(DeleteTask event, Emitter<TaskState> emit) async {
    try {
      await taskRepository.deleteTask(event.id);
      final updatedTasks = state.tasks.where((t) => t.id != event.id).toList();
      emit(state.copyWith(
        tasks: updatedTasks,
        filteredTasks: _applyFilters(updatedTasks, state.searchQuery, state.filterStatus),
      ));
    } catch (e) {
      // Handle delete error
    }
  }

  Future<void> _onFilterTasks(FilterTasks event, Emitter<TaskState> emit) async {
    final query = event.query ?? state.searchQuery;
    final status = event.status ?? state.filterStatus;
    
    emit(state.copyWith(
      searchQuery: query,
      filterStatus: status,
      filteredTasks: _applyFilters(state.tasks, query, status),
    ));
  }

  List<Task> _applyFilters(List<Task> tasks, String query, String? status) {
    return tasks.where((task) {
      final matchesQuery = task.title.toLowerCase().contains(query.toLowerCase());
      final matchesStatus = status == null || status == 'All' || task.status.value == status;
      return matchesQuery && matchesStatus;
    }).toList();
  }
}
