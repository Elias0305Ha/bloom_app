import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../models/todo.dart';
import '../services/storage_service.dart';

class DailyHubPage extends StatefulWidget {
  const DailyHubPage({super.key});

  @override
  State<DailyHubPage> createState() => _DailyHubPageState();
}

class _DailyHubPageState extends State<DailyHubPage> {
  bool _isLoading = true;
  List<Todo> _todos = const [];
  DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _today = DateTime(_today.year, _today.month, _today.day);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await StorageService.getTodosForDate(_today);
      setState(() {
        _todos = results;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTodoDialog() async {
    final titleController = TextEditingController();
    String priority = 'medium';
    bool impactOnMood = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority:'),
                const SizedBox(width: 8),
                StatefulBuilder(
                  builder: (ctx, setInner) => DropdownButton<String>(
                    value: priority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (v) => setInner(() => priority = v ?? 'medium'),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                StatefulBuilder(
                  builder: (ctx, setInner) => Checkbox(
                    value: impactOnMood,
                    onChanged: (v) => setInner(() => impactOnMood = v ?? false),
                  ),
                ),
                const Expanded(child: Text('Has strong impact on mood')),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (result == true && titleController.text.trim().isNotEmpty) {
      final newTodo = Todo(
        date: _today,
        title: titleController.text.trim(),
        priority: priority,
        impactOnMood: impactOnMood,
        subtasks: const [],
      );
      final id = await StorageService.createTodo(newTodo);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Todo added (id: ${id.oid})')),
      );
    }
  }

  Future<void> _toggleTodoDone(Todo todo, bool done) async {
    final updated = todo.copyWith(status: done ? 'done' : 'open');
    await StorageService.updateTodo(updated);
    await _load();
  }

  Future<void> _addSubtask(Todo todo) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Subtask title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      final updated = todo.copyWith(
        subtasks: [
          ...todo.subtasks,
          Subtask(id: ObjectId(), title: controller.text.trim(), isDone: false),
        ],
      );
      await StorageService.updateTodo(updated);
      await _load();
    }
  }

  Future<void> _toggleSubtask(Todo todo, Subtask subtask, bool value) async {
    final updatedSubtasks = todo.subtasks
        .map((s) => s.id == subtask.id ? s.copyWith(isDone: value) : s)
        .toList();
    // If all done → mark parent done; if any undone → open
    final allDone = updatedSubtasks.isNotEmpty && updatedSubtasks.every((s) => s.isDone);
    final updated = todo.copyWith(
      subtasks: updatedSubtasks,
      status: allDone ? 'done' : (updatedSubtasks.any((s) => s.isDone) ? 'in_progress' : 'open'),
    );
    await StorageService.updateTodo(updated);
    await _load();
  }

  Widget _buildQuoteCard() {
    const quote = 'Small daily improvements lead to stunning long-term results.';
    const author = '— Robin Sharma';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            Icon(Icons.format_quote, color: Colors.green),
            SizedBox(width: 12),
            Expanded(child: Text('$quote\n$author')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Hub'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodoDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Today — ${_today.toLocal().toString().split(' ').first}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildQuoteCard(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Todos', style: Theme.of(context).textTheme.titleMedium),
                              TextButton.icon(
                                onPressed: _addTodoDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_todos.isEmpty)
                            const Text('No todos yet. Create your first one!')
                          else
                            ..._todos.map((t) => _TodoTile(
                                  todo: t,
                                  onToggleDone: (v) => _toggleTodoDone(t, v),
                                  onAddSubtask: () => _addSubtask(t),
                                  onToggleSubtask: (s, v) => _toggleSubtask(t, s, v),
                                )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onAddSubtask;
  final void Function(Subtask, bool) onToggleSubtask;

  const _TodoTile({
    required this.todo,
    required this.onToggleDone,
    required this.onAddSubtask,
    required this.onToggleSubtask,
  });

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = todo.progressPercent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ExpansionTile(
          leading: Checkbox(
            value: percent == 100,
            onChanged: (v) => onToggleDone(v ?? false),
          ),
          title: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _priorityColor(todo.priority),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(todo.title)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 4),
              Text('$percent% • ${todo.subtasks.where((s) => s.isDone).length}/${todo.subtasks.length}'),
            ],
          ),
          children: [
            if ((todo.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(todo.description!),
              ),
            ...todo.subtasks.map((s) => ListTile(
                  leading: Checkbox(
                    value: s.isDone,
                    onChanged: (v) => onToggleSubtask(s, v ?? false),
                  ),
                  title: Text(s.title),
                )),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSubtask,
                icon: const Icon(Icons.add_task),
                label: const Text('Add subtask'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
