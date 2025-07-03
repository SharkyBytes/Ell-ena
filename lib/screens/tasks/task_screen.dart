import 'package:flutter/material.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final List<Task> _tasks = [
    Task(
      title: 'Design UI mockups',
      description: 'Create mockups for the new dashboard',
      dueDate: DateTime(2025, 8, 4),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
    ),
    Task(
      title: 'Implement authentication',
      description: 'Add user authentication flow',
      dueDate: DateTime(2025, 7, 4),
      priority: TaskPriority.high,
      status: TaskStatus.todo,
    ),
    Task(
      title: 'Write documentation',
      description: 'Document the API endpoints',
      dueDate: DateTime(2025, 9, 4),
      priority: TaskPriority.medium,
      status: TaskStatus.completed,
    ),
    // Add more sample tasks here
  ];

  TaskStatus _selectedStatus = TaskStatus.inProgress;

  @override
  Widget build(BuildContext context) {
    final completedTasks =
        _tasks.where((task) => task.status == TaskStatus.completed).length;
    final inProgressTasks =
        _tasks.where((task) => task.status == TaskStatus.inProgress).length;
    final todoTasks =
        _tasks.where((task) => task.status == TaskStatus.todo).length;
    final totalTasks = _tasks.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          _buildProgressHeader(
            completedTasks: completedTasks,
            inProgressTasks: inProgressTasks,
            todoTasks: todoTasks,
            totalTasks: totalTasks,
          ),
          const SizedBox(height: 16),
          _buildStatusTabs(),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildProgressHeader({
    required int completedTasks,
    required int inProgressTasks,
    required int todoTasks,
    required int totalTasks,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressStat(
                label: 'Completed',
                value: completedTasks,
                total: totalTasks,
                color: Colors.green.shade400,
              ),
              _buildProgressStat(
                label: 'In Progress',
                value: inProgressTasks,
                total: totalTasks,
                color: Colors.orange.shade400,
              ),
              _buildProgressStat(
                label: 'To Do',
                value: todoTasks,
                total: totalTasks,
                color: Colors.blue.shade400,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(height: 8, color: Colors.grey.shade800),
                Row(
                  children: [
                    _buildProgressBar(
                      width: completedTasks / totalTasks,
                      color: Colors.green.shade400,
                    ),
                    _buildProgressBar(
                      width: inProgressTasks / totalTasks,
                      color: Colors.orange.shade400,
                    ),
                    _buildProgressBar(
                      width: todoTasks / totalTasks,
                      color: Colors.blue.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
   final percentage = total > 0 ? (value / total * 100).round() : 0;
    return Column(
      children: [
        Text(
          '$percentage%',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProgressBar({required double width, required Color color}) {
    return Container(
      height: 8,
      width: MediaQuery.of(context).size.width * width - 32 * width,
      color: color,
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children:
            TaskStatus.values.map((status) {
              final isSelected = status == _selectedStatus;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStatus = status),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? status.color.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? status.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: isSelected ? status.color : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTaskList() {
    final filteredTasks =
        _tasks.where((task) => task.status == _selectedStatus).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return _TaskCard(task: task);
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: task.priority.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      task.priority.icon,
                      color: task.priority.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.priority.label,
                      style: TextStyle(
                        color: task.priority.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  task.formattedDueDate,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Task {
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;

  Task({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  String get formattedDueDate {
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }
}

enum TaskPriority {
  high(Icons.priority_high, Colors.red, 'High Priority'),
  medium(Icons.radio_button_checked, Colors.orange, 'Medium Priority'),
  low(Icons.arrow_downward, Colors.green, 'Low Priority');

  final IconData icon;
  final MaterialColor color;
  final String label;

  const TaskPriority(this.icon, this.color, this.label);
}

enum TaskStatus {
  completed(Colors.green, 'Completed'),
  inProgress(Colors.orange, 'In Progress'),
  todo(Colors.blue, 'To Do');

  final MaterialColor color;
  final String label;

  const TaskStatus(this.color, this.label);
}
