import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import '../../data/models/task_model.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasks());
  }

  String? _getBlockingTaskName(Task task, List<Task> allTasks) {
    if (task.blockedById == null) return null;
    final blockingTask = allTasks.cast<Task?>().firstWhere(
      (t) => t?.id == task.blockedById,
      orElse: () => null,
    );
    if (blockingTask != null && blockingTask.status != TaskStatus.done) {
      return blockingTask.title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
        title: const Text('My Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<TaskBloc>().add(FilterTasks(query: value));
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: BlocBuilder<TaskBloc, TaskState>(
                    builder: (context, state) {
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: state.filterStatus ?? 'All',
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        items: ['All', ...TaskStatus.values.map((e) => e.value)]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          context.read<TaskBloc>().add(FilterTasks(status: value));
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state.status == TaskStatusEnum.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == TaskStatusEnum.loading || state.status == TaskStatusEnum.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.filteredTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'No tasks found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TaskBloc>().add(LoadTasks());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.filteredTasks.length,
              itemBuilder: (context, index) {
                final task = state.filteredTasks[index];
                final blockingTaskName = _getBlockingTaskName(task, state.tasks);
                final isBlocked = blockingTaskName != null;

                return TaskCard(
                  task: task,
                  isBlocked: isBlocked,
                  searchQuery: state.searchQuery,
                  onTap: () {
                    if (isBlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('The task is currently blocked by ${blockingTaskName}')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskFormScreen(taskToEdit: task),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      context.read<TaskBloc>().add(DeleteTask(task.id!));
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
  }
}
