import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../data/models/task_model.dart';
import '../bloc/task_bloc.dart';
import '../bloc/task_event.dart';
import '../bloc/task_state.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? taskToEdit;

  const TaskFormScreen({Key? key, this.taskToEdit}) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _descController;
  
  DateTime _selectedDate = DateTime.now();
  TaskStatus _selectedStatus = TaskStatus.todo;
  int? _blockedById;

  bool get isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController(text: widget.taskToEdit?.title ?? '');
    _descController = TextEditingController(text: widget.taskToEdit?.description ?? '');
    if (widget.taskToEdit != null) {
      _selectedDate = widget.taskToEdit!.dueDate;
      _selectedStatus = widget.taskToEdit!.status;
      _blockedById = widget.taskToEdit!.blockedById;
    } else {
      _loadDraft();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString('task_draft');
    if (draftStr != null) {
      final draft = json.decode(draftStr);
      setState(() {
        _titleController.text = draft['title'] ?? '';
        _descController.text = draft['description'] ?? '';
      });
    }
  }

  Future<void> _saveDraft() async {
    if (isEditing) return;
    final prefs = await SharedPreferences.getInstance();
    if (_titleController.text.isEmpty && _descController.text.isEmpty) {
      await prefs.remove('task_draft');
      return;
    }
    final draft = {
      'title': _titleController.text,
      'description': _descController.text,
    };
    await prefs.setString('task_draft', json.encode(draft));
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('task_draft');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearDraft(); // User is backing out, clear the draft
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        title: _titleController.text,
        description: _descController.text,
        dueDate: _selectedDate,
        status: _selectedStatus,
        blockedById: _blockedById,
      );

      if (isEditing) {
        context.read<TaskBloc>().add(UpdateTask(widget.taskToEdit!.id!, task));
      } else {
        context.read<TaskBloc>().add(CreateTask(task));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: \${state.submitError}')),
          );
        } else if (!state.isSubmitting && state.status == TaskStatusEnum.loaded && state.submitError == null) {
          if (!isEditing) _clearDraft();
          Navigator.pop(context);
        }
      },
      listenWhen: (prev, current) => prev.isSubmitting && !current.isSubmitting,
      builder: (context, state) {
        List<Task> availableTasksToBlock = state.tasks
            .where((t) => t.id != widget.taskToEdit?.id)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Task' : 'New Task'),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        onChanged: (_) => _saveDraft(),
                        decoration: const InputDecoration(labelText: 'Task Title'),
                        validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descController,
                        onChanged: (_) => _saveDraft(),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (v) => v!.isEmpty ? 'Please enter a description' : null,
                      ),
                      const SizedBox(height: 20),
                      Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text('Due Date', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
                          trailing: const Icon(Icons.calendar_month, color: Color(0xFF6366F1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<TaskStatus>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: TaskStatus.values
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.value)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int?>(
                        value: _blockedById,
                        decoration: const InputDecoration(labelText: 'Blocked By (Dependency)'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('None (Unblocked)')),
                          ...availableTasksToBlock.map(
                            (t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.title)),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => _blockedById = val);
                        },
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: state.isSubmitting ? null : () => _onSave(context),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Task', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 40), // Bottom padding
                    ],
                  ),
                ),
              ),
              if (state.isSubmitting)
                Container(
                  color: Colors.black.withOpacity(0.05),
                ),
            ],
          ),
        );
      },
    );
  }
}
