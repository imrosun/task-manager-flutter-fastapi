import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String searchQuery;

  const TaskCard({
    Key? key,
    required this.task,
    required this.isBlocked,
    required this.onTap,
    required this.onDelete,
    this.searchQuery = '',
  }) : super(key: key);

  List<TextSpan> _buildHighlightedText(String text, String query, BuildContext context) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }
    
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int startIndex = 0;
    List<TextSpan> spans = [];

    while (true) {
      final index = lowerText.indexOf(lowerQuery, startIndex);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(startIndex)));
        break;
      }
      if (index > startIndex) {
        spans.add(TextSpan(text: text.substring(startIndex, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ));
      startIndex = index + query.length;
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBlocked ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: isBlocked ? Colors.grey.shade100 : Colors.white,
        child: InkWell(
          onTap: onTap, // Optional: if user wants to see it even if blocked, but typically locked. Let's allow tapping to see details maybe. Wait, requirement says "visually distinct until A is Done". It didn't explicitly restrict clicking, but usually locked. Let's make it null if you want to restrict, but maybe let's allow them to open it but not edit. Let's just allow it for now.
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isBlocked) 
                            const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                            ),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isBlocked ? Colors.grey.shade600 : Colors.black87,
                                ),
                                children: _buildHighlightedText(task.title, searchQuery, context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusChip(context, task.status),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(task.dueDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: onDelete,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, TaskStatus status) {
    Color color;
    switch (status) {
      case TaskStatus.todo:
        color = Colors.blueGrey;
        break;
      case TaskStatus.inProgress:
        color = Colors.orangeAccent;
        break;
      case TaskStatus.done:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
