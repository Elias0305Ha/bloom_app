import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../models/todo.dart';
import '../models/daily_review.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';

class DailyHubPage extends StatefulWidget {
  const DailyHubPage({super.key});

  @override
  State<DailyHubPage> createState() => _DailyHubPageState();
}

class _DailyHubPageState extends State<DailyHubPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Todo> _todos = const [];
  DailyReview? _todayReview;
  List<MoodEntry> _todayMoods = [];
  DateTime _today = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _today = DateTime(_today.year, _today.month, _today.day);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Load data in parallel for better performance
      final futures = await Future.wait([
        StorageService.getTodosForDate(_today),
        StorageService.getDailyReview(_today),
        StorageService.getMoodEntries(),
      ]);
      
      final results = futures[0] as List<Todo>;
      final review = futures[1] as DailyReview?;
      final allMoods = futures[2] as List<MoodEntry>;
      
      // Filter today's moods efficiently
      final todayMoods = allMoods.where((mood) {
        final moodDate = DateTime(mood.date.year, mood.date.month, mood.date.day);
        return moodDate.isAtSameMomentAs(_today);
      }).toList();
      
      setState(() {
        _todos = results;
        _todayReview = review;
        _todayMoods = todayMoods;
      });
      
      // Start animation after data is loaded
      _animationController.forward();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _todos = [];
        _todayReview = null;
        _todayMoods = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _derivedCompletionPercent() {
    if (_todos.isEmpty) return 0;
    int sum = 0;
    for (final t in _todos) { sum += t.progressPercent; }
    return (sum / _todos.length).round();
  }

  // Smart helper methods for Phase 1
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentMood() {
    if (_todayMoods.isEmpty) return 'No mood logged yet';
    final latestMood = _todayMoods.last;
    return '${_getMoodEmoji(latestMood.mood)} ${latestMood.mood} (${latestMood.intensity}/10)';
  }

  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'anxious': return '😰';
      case 'excited': return '🤩';
      case 'calm': return '😌';
      case 'tired': return '😴';
      case 'confused': return '😕';
      case 'grateful': return '🙏';
      case 'motivated': return '💪';
      default: return '😐';
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy': return Colors.amber.shade600; // Darker, more sophisticated yellow
      case 'sad': return Colors.blue.shade400;
      case 'angry': return Colors.red.shade400;
      case 'anxious': return Colors.orange.shade400;
      case 'excited': return Colors.pink.shade400;
      case 'calm': return Colors.green.shade400;
      case 'tired': return Colors.grey.shade400;
      case 'confused': return Colors.purple.shade400;
      case 'grateful': return Colors.teal.shade400;
      case 'motivated': return Colors.deepOrange.shade400;
      default: return Colors.grey.shade300;
    }
  }

  int _getEnergyLevel() {
    if (_todayMoods.isEmpty) return 5;
    final avgIntensity = _todayMoods.map((m) => m.intensity).reduce((a, b) => a + b) / _todayMoods.length;
    return avgIntensity.round();
  }

  String _getMotivationalQuote() {
    final quotes = [
      'Small daily improvements lead to stunning long-term results. — Robin Sharma',
      'The way to get started is to quit talking and begin doing. — Walt Disney',
      'Don\'t be pushed around by the fears in your mind. Be led by the dreams in your heart. — Roy T. Bennett',
      'Success is not final, failure is not fatal: it is the courage to continue that counts. — Winston Churchill',
      'The only way to do great work is to love what you do. — Steve Jobs',
      'Believe you can and you\'re halfway there. — Theodore Roosevelt',
      'It does not matter how slowly you go as long as you do not stop. — Confucius',
      'The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  List<String> _getTodayActivities() {
    final activities = <String>[];
    for (final mood in _todayMoods) {
      activities.addAll(mood.activities);
    }
    return activities.toSet().toList(); // Remove duplicates
  }

  Future<void> _openDailyReviewDialog() async {
    final completion = _derivedCompletionPercent();
    final wellCtrl = TextEditingController(text: _todayReview?.wentWell ?? '');
    final improveCtrl = TextEditingController(text: _todayReview?.improve ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End of Day Review'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completion: $completion%'),
              const SizedBox(height: 12),
              TextField(
                controller: wellCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What went well?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: improveCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'What can you improve tomorrow?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      final review = DailyReview(
        id: _todayReview?.id,
        date: _today,
        completionPercent: completion,
        wentWell: wellCtrl.text.trim().isEmpty ? null : wellCtrl.text.trim(),
        improve: improveCtrl.text.trim().isEmpty ? null : improveCtrl.text.trim(),
      );
      await StorageService.saveDailyReview(review);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily review saved')));
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

  Future<void> _editTodoTitle(Todo todo) async {
    final controller = TextEditingController(text: todo.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty) {
      await StorageService.updateTodo(todo.copyWith(title: controller.text.trim()));
      await _load();
    }
  }

  Future<void> _confirmDeleteTodo(Todo todo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && todo.id != null) {
      await StorageService.deleteTodo(todo.id!);
      await _load();
    }
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

  Future<void> _deleteSubtask(Todo todo, Subtask subtask) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Subtask'),
        content: const Text('Remove this subtask?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      final updated = todo.copyWith(
        subtasks: todo.subtasks.where((s) => s.id != subtask.id).toList(),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50.withOpacity(0.3),
              Colors.purple.shade50.withOpacity(0.3),
              Colors.indigo.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: _isLoading
            ? _buildSkeletonLoader()
            : RefreshIndicator(
                onRefresh: _load,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // Smart Header
                      _buildSmartHeader(),
                      // Quick Actions
                      _buildQuickActions(),
                      // Intelligence Dashboard
                      _buildIntelligenceDashboard(),
                      // Smart Todo List
                      _buildSmartTodoList(),
                      // Daily Review
                      _buildDailyReview(),
                      // Bottom padding
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTodoDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Widget _buildSmartHeader() {
    final currentMood = _todayMoods.isNotEmpty ? _todayMoods.last.mood : 'neutral';
    final moodColor = _getMoodColor(currentMood);
    
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                moodColor.withOpacity(0.8),
                moodColor.withOpacity(0.6),
                moodColor.withOpacity(0.4),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _getTimeBasedGreeting(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today, ${_today.day}/${_today.month}/${_today.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getCurrentMood(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.mood,
                label: 'Log Mood',
                color: Colors.orange,
                onTap: () {
                  // Navigate to home page for mood logging
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add_task,
                label: 'Add Todo',
                color: Colors.green,
                onTap: _addTodoDialog,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.rate_review,
                label: 'Review',
                color: Colors.purple,
                onTap: _openDailyReviewDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelligenceDashboard() {
    final completion = _derivedCompletionPercent();
    final energy = _getEnergyLevel();
    final activities = _getTodayActivities();
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Progress Ring
            _buildProgressRing(completion),
            const SizedBox(height: 16),
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Energy Level',
                    '$energy/10',
                    Icons.battery_charging_full,
                    _getEnergyColor(energy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Moods Today',
                    '${_todayMoods.length}',
                    Icons.psychology,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Activities',
                    '${activities.length}',
                    Icons.directions_run,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Motivational Quote
            _buildQuoteCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRing(int completion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: completion / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletionColor(completion),
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$completion%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getCompletionMessage(completion),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.format_quote, color: Colors.purple.shade600, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _getMotivationalQuote(),
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.purple.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartTodoList() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Focus',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addTodoDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_todos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No todos yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first todo to get started!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                else
                  ..._todos.map((t) => _TodoTile(
                        todo: t,
                        onToggleDone: (v) => _toggleTodoDone(t, v),
                        onAddSubtask: () => _addSubtask(t),
                        onToggleSubtask: (s, v) => _toggleSubtask(t, s, v),
                        onEditTodo: () => _editTodoTitle(t),
                        onDeleteTodo: () => _confirmDeleteTodo(t),
                        onDeleteSubtask: (s) => _deleteSubtask(t, s),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReview() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Evening Review',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openDailyReviewDialog,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save Review'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_todayReview != null) ...[
                  _buildReviewItem('What went well', _todayReview!.wentWell ?? 'Not specified'),
                  const SizedBox(height: 12),
                  _buildReviewItem('Areas to improve', _todayReview!.improve ?? 'Not specified'),
                ] else
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Take a moment to reflect on your day and save your insights.',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // Helper methods for colors and messages
  Color _getEnergyColor(int energy) {
    if (energy >= 8) return Colors.green;
    if (energy >= 6) return Colors.yellow;
    if (energy >= 4) return Colors.orange;
    return Colors.red;
  }

  Color _getCompletionColor(int completion) {
    if (completion >= 80) return Colors.green;
    if (completion >= 60) return Colors.yellow;
    if (completion >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getCompletionMessage(int completion) {
    if (completion >= 90) return 'Outstanding! You\'re on fire! 🔥';
    if (completion >= 80) return 'Excellent work! Keep it up! 💪';
    if (completion >= 60) return 'Good progress! You\'re doing great! 👍';
    if (completion >= 40) return 'Keep pushing forward! 💪';
    if (completion >= 20) return 'Every step counts! Keep going! 🚀';
    return 'Ready to start your journey? Let\'s go! 🌟';
  }

  Widget _buildSkeletonLoader() {
    return CustomScrollView(
      slivers: [
        // Header skeleton
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade200],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 32,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Content skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick actions skeleton
                Row(
                  children: List.generate(3, (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
                ),
                const SizedBox(height: 16),
                // Progress ring skeleton
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats skeleton
                Row(
                  children: List.generate(3, (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onAddSubtask;
  final void Function(Subtask, bool) onToggleSubtask;
  final VoidCallback onEditTodo;
  final VoidCallback onDeleteTodo;
  final void Function(Subtask) onDeleteSubtask;

  const _TodoTile({
    required this.todo,
    required this.onToggleDone,
    required this.onAddSubtask,
    required this.onToggleSubtask,
    required this.onEditTodo,
    required this.onDeleteTodo,
    required this.onDeleteSubtask,
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
    final isCompleted = percent == 100;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade300 : Colors.grey.shade200,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : Colors.grey.shade300,
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8, right: 80), // Add right padding to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: percent / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _priorityColor(todo.priority),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    '$percent% Complete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                  Text(
                    '${todo.subtasks.where((s) => s.isDone).length}/${todo.subtasks.length} subtasks',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (todo.impactOnMood) ...[
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                    ),
                    Icon(
                      Icons.favorite,
                      size: 10,
                      color: Colors.pink.shade400,
                    ),
                    Text(
                      'Mood',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.pink.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 70,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onEditTodo,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDeleteTodo,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete_outline, size: 14, color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        ),
        children: [
          if ((todo.description ?? '').isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                todo.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
          if (todo.subtasks.isNotEmpty) ...[
            const Divider(),
            ...todo.subtasks.map((s) => Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: s.isDone,
                  onChanged: (v) => onToggleSubtask(s, v ?? false),
                ),
                title: Text(
                  s.title,
                  style: TextStyle(
                    decoration: s.isDone ? TextDecoration.lineThrough : null,
                    color: s.isDone ? Colors.grey : Colors.black87,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
                  onPressed: () => onDeleteSubtask(s),
                ),
              ),
            )),
          ],
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: onAddSubtask,
              icon: const Icon(Icons.add_task, size: 16),
              label: const Text('Add subtask'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          // Optional: Add haptic feedback or animation
        },
      ),
    );
  }
}
