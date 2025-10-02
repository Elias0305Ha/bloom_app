import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import '../models/goal.dart';
import '../services/storage_service.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Goal> _goals = [];
  Map<String, dynamic> _stats = {};
  String _selectedCategory = 'All';
  String _selectedPriority = 'All';
  String _selectedStatus = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'All',
    'Personal',
    'Career',
    'Health',
    'Learning',
    'Financial',
    'Relationships',
    'Hobbies',
  ];

  final List<String> _priorities = ['All', 'High', 'Medium', 'Low'];
  final List<String> _statuses = ['All', 'Active', 'Completed', 'Paused', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load data in parallel for better performance
      final futures = await Future.wait([
        StorageService.getAllGoals(),
        StorageService.getGoalStats(),
      ]);

      if (mounted) {
        setState(() {
          _goals = futures[0] as List<Goal>;
          _stats = futures[1] as Map<String, dynamic>;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading goal data: $e');
      if (mounted) {
        setState(() {
          _goals = [];
          _stats = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Goal> get _filteredGoals {
    return _goals.where((goal) {
      final categoryMatch = _selectedCategory == 'All' || goal.category.toLowerCase() == _selectedCategory.toLowerCase();
      final priorityMatch = _selectedPriority == 'All' || goal.priority == _selectedPriority.toLowerCase();
      final statusMatch = _selectedStatus == 'All' || goal.status == _selectedStatus.toLowerCase();
      return categoryMatch && priorityMatch && statusMatch;
    }).toList();
  }

  Future<void> _showAddGoalDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final motivationController = TextEditingController();
    String category = 'Personal';
    String priority = 'medium';
    DateTime startDate = DateTime.now();
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));
    List<String> tags = [];
    List<String> obstacles = [];
    List<String> resources = [];
    int impactOnMood = 3;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Goal Title *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.skip(1).map((cat) => 
                    DropdownMenuItem(value: cat, child: Text(cat))
                  ).toList(),
                  onChanged: (v) => setState(() => category = v ?? 'Personal'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (v) => setState(() => priority = v ?? 'medium'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Start Date'),
                        controller: TextEditingController(
                          text: '${startDate.day}/${startDate.month}/${startDate.year}',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => startDate = date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Target Date'),
                        controller: TextEditingController(
                          text: '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (date != null) {
                            setState(() => targetDate = date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivationController,
                  decoration: const InputDecoration(
                    labelText: 'Why is this goal important to you?',
                    hintText: 'Describe your motivation...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Mood Impact:'),
                    Expanded(
                      child: Slider(
                        value: impactOnMood.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: impactOnMood.toString(),
                        onChanged: (v) => setState(() => impactOnMood = v.round()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final newGoal = Goal(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        category: category,
        priority: priority,
        startDate: startDate,
        targetDate: targetDate,
        motivation: motivationController.text.trim(),
        impactOnMood: impactOnMood,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await StorageService.createGoal(newGoal);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal created successfully!')),
      );
    }
  }

  Future<void> _completeGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Goal'),
        content: Text('Are you sure you want to mark "${goal.title}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && goal.id != null) {
      await StorageService.completeGoal(goal.id!);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${goal.title} completed! 🎉')),
      );
    }
  }

  Future<void> _deleteGoal(Goal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${goal.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true && goal.id != null) {
      await StorageService.deleteGoal(goal.id!);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${goal.title} deleted')),
      );
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red.shade400;
      case 'medium': return Colors.orange.shade400;
      case 'low': return Colors.green.shade400;
      default: return Colors.grey.shade400;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.blue.shade400;
      case 'completed': return Colors.green.shade400;
      case 'paused': return Colors.orange.shade400;
      case 'cancelled': return Colors.red.shade400;
      default: return Colors.grey.shade400;
    }
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
              Colors.indigo.shade50.withOpacity(0.3),
              Colors.purple.shade50.withOpacity(0.3),
              Colors.pink.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: _isLoading
            ? _buildSkeletonLoader()
            : RefreshIndicator(
                onRefresh: _loadData,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      _buildHeader(),
                      _buildStatsOverview(),
                      _buildFilters(),
                      _buildGoalsList(),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade400, Colors.purple.shade400],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Goals & Dreams',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Turn your dreams into reality',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Your Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active Goals',
                        '${_stats['activeGoals'] ?? 0}',
                        Icons.track_changes,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        '${_stats['completedGoals'] ?? 0}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Overdue',
                        '${_stats['overdueGoals'] ?? 0}',
                        Icons.warning,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _stats['averageProgress'] != null ? (_stats['averageProgress'] as int) / 100.0 : 0.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                ),
                const SizedBox(height: 8),
                Text(
                  'Average Progress: ${_stats['averageProgress'] ?? 0}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Use Wrap instead of Row to prevent overflow
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: _categories.map((category) => 
                          DropdownMenuItem(value: category, child: Text(category, overflow: TextOverflow.ellipsis))
                        ).toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value ?? 'All'),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: _priorities.map((priority) => 
                          DropdownMenuItem(value: priority, child: Text(priority, overflow: TextOverflow.ellipsis))
                        ).toList(),
                        onChanged: (value) => setState(() => _selectedPriority = value ?? 'All'),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: _statuses.map((status) => 
                          DropdownMenuItem(value: status, child: Text(status, overflow: TextOverflow.ellipsis))
                        ).toList(),
                        onChanged: (value) => setState(() => _selectedStatus = value ?? 'All'),
                      ),
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

  Widget _buildGoalsList() {
    final filteredGoals = _filteredGoals;
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Goals (${filteredGoals.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddGoalDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (filteredGoals.isEmpty)
              _buildEmptyState()
            else
              ...filteredGoals.map((goal) => _GoalCard(
                goal: goal,
                onComplete: () => _completeGoal(goal),
                onDelete: () => _deleteGoal(goal),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.flag, size: 48, color: Colors.indigo.shade400),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start achieving your dreams by setting your first goal!',
            style: TextStyle(color: Colors.indigo.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade400,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Stats skeleton
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),
                // Goal cards skeleton - reduced count for faster loading
                ...List.generate(2, (index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onComplete,
    required this.onDelete,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red.shade400;
      case 'medium': return Colors.orange.shade400;
      case 'low': return Colors.green.shade400;
      default: return Colors.grey.shade400;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.blue.shade400;
      case 'completed': return Colors.green.shade400;
      case 'paused': return Colors.orange.shade400;
      case 'cancelled': return Colors.red.shade400;
      default: return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = goal.isOverdue;
    final daysRemaining = goal.daysRemaining;
    final progress = goal.overallProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.shade300 : Colors.grey.shade200,
          width: isOverdue ? 2 : 1,
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          goal.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: goal.status == 'completed' ? TextDecoration.lineThrough : null,
            color: goal.status == 'completed' ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(goal.status),
                const SizedBox(width: 8),
                _buildPriorityChip(goal.priority),
                const SizedBox(width: 8),
                if (goal.impactOnMood >= 4)
                  _buildMoodImpactChip(),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100.0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(goal.status)),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$progress% Complete',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  isOverdue 
                    ? 'Overdue by ${-daysRemaining} days'
                    : daysRemaining > 0 
                      ? '$daysRemaining days left'
                      : 'Due today',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey,
                    fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            if (goal.status == 'active')
              PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('Complete'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'complete') onComplete();
            if (value == 'delete') onDelete();
          },
        ),
        children: [
          if (goal.description.isNotEmpty) ...[
            Text(
              goal.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.category, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                goal.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (goal.milestones.isNotEmpty)
                Text(
                  '${goal.completedMilestonesCount}/${goal.totalMilestonesCount} milestones',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    String text = status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color = _getPriorityColor(priority);
    String text = priority.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMoodImpactChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 12, color: Colors.pink.shade400),
          const SizedBox(width: 4),
          Text(
            'Mood+',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.pink.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
