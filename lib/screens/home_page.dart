import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/mood_button.dart';
import '../widgets/activity_button.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'timeline_page.dart';
import 'weekly_review_page.dart';
import 'daily_hub_page.dart';
import 'habit_tracker_page.dart';
import 'ai_insights_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool _isNavigating = false;
  String? selectedMood;
  List<String> selectedActivities = [];
  List<String> selectedTriggers = [];
  int intensity = 5;
  final TextEditingController _noteController = TextEditingController();
  bool isSaving = false;
  bool isSaved = false;
  bool _isLoading = true;
  List<MoodEntry> _recentMoods = [];
  int _moodStreak = 0;
  String _currentGreeting = '';
  String _currentMoodTheme = 'neutral';
  List<String> _smartSuggestions = [];
  bool _showCelebration = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  Future<void> _safePush(Widget page) async {
    if (_isNavigating || !mounted) return;
    setState(() => _isNavigating = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigation failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final moods = await StorageService.getMoodEntries();
      final today = DateTime.now();
      final todayMoods = moods.where((m) => 
        m.date.year == today.year &&
        m.date.month == today.month &&
        m.date.day == today.day
      ).toList();
      
      setState(() {
        _recentMoods = moods.take(5).toList();
        _moodStreak = _calculateMoodStreak(moods);
        _currentGreeting = _getTimeBasedGreeting();
        _smartSuggestions = _generateSmartSuggestions();
      });
    } catch (e) {
      print('Error loading initial data: $e');
    } finally {
      setState(() => _isLoading = false);
      _fadeController.forward();
      _slideController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  int _calculateMoodStreak(List<MoodEntry> moods) {
    if (moods.isEmpty) return 0;
    
    final sortedMoods = moods.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final mood in sortedMoods) {
      final moodDate = DateTime(mood.date.year, mood.date.month, mood.date.day);
      final expectedDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      if (moodDate.isAtSameMomentAs(expectedDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  void _updateMoodTheme(String mood) {
    setState(() {
      _currentMoodTheme = mood.toLowerCase();
    });
  }

  List<Color> _getMoodColors(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return [Colors.yellow.shade300, Colors.orange.shade300, Colors.pink.shade300];
      case 'sad':
        return [Colors.blue.shade300, Colors.indigo.shade300, Colors.purple.shade300];
      case 'angry':
        return [Colors.red.shade300, Colors.deepOrange.shade300, Colors.pink.shade300];
      case 'calm':
        return [Colors.green.shade300, Colors.teal.shade300, Colors.cyan.shade300];
      case 'tired':
        return [Colors.grey.shade300, Colors.blueGrey.shade300, Colors.brown.shade300];
      default:
        return [Colors.blue.shade50, Colors.purple.shade50, Colors.pink.shade50];
    }
  }

  List<String> _generateSmartSuggestions() {
    final hour = DateTime.now().hour;
    final suggestions = <String>[];
    
    // Time-based suggestions
    if (hour < 12) {
      suggestions.addAll([
        "Good morning! How did you sleep? 🌅",
        "Ready to start your day? What's your mood? ☀️",
        "Morning energy check - how are you feeling? ⚡"
      ]);
    } else if (hour < 17) {
      suggestions.addAll([
        "How's your afternoon going? 🌤️",
        "Midday mood check - feeling productive? 💪",
        "Afternoon vibes - what's your current mood? 🌈"
      ]);
    } else {
      suggestions.addAll([
        "Evening reflection time 🌙",
        "How was your day overall? 🌟",
        "Wind down mood - how are you feeling? 🕯️"
      ]);
    }
    
    // Activity-based suggestions (if we have recent activities)
    if (_recentMoods.isNotEmpty) {
      final lastMood = _recentMoods.first;
      if (lastMood.activities.contains('Work')) {
        suggestions.add("Just finished work - how do you feel now? 💼");
      }
      if (lastMood.activities.contains('Exercise')) {
        suggestions.add("Post-workout mood check - feeling energized? 🏃‍♂️");
      }
      if (lastMood.activities.contains('Social')) {
        suggestions.add("Social time over - how was it? 👥");
      }
    }
    
    // Streak-based suggestions
    if (_moodStreak >= 7) {
      suggestions.add("Amazing streak! Keep it up! 🔥");
    } else if (_moodStreak >= 3) {
      suggestions.add("Great consistency! You're building a habit! 💪");
    }
    
    return suggestions.take(3).toList();
  }

  void _showStreakCelebration() {
    if (_moodStreak > 0 && (_moodStreak % 7 == 0 || _moodStreak == 1)) {
      setState(() => _showCelebration = true);
      
      // Show celebration dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _moodStreak == 1 ? '🎉 First Entry!' : '🔥 $_moodStreak Day Streak!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                _moodStreak == 1 
                  ? 'Welcome to your mood journey!'
                  : 'You\'re building an amazing habit!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _showCelebration = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Awesome!'),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }



  void _selectMood(String mood) {
    HapticFeedback.lightImpact();
    _updateMoodTheme(mood);
    setState(() {
      selectedMood = mood;
    });
  }

  void _toggleActivity(String activity) {
    HapticFeedback.selectionClick();
    setState(() {
      if (selectedActivities.contains(activity)) {
        selectedActivities.remove(activity);
      } else {
        selectedActivities.add(activity);
      }
    });
  }

  void _toggleTrigger(String trigger) {
    HapticFeedback.selectionClick();
    setState(() {
      if (selectedTriggers.contains(trigger)) {
        selectedTriggers.remove(trigger);
      } else {
        selectedTriggers.add(trigger);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (selectedMood == null) {
      _showSnackBar('Please select a mood first!');
      return;
    }

    setState(() {
      isSaving = true;
      isSaved = false;
    });

    try {
      final entry = MoodEntry(
        mood: selectedMood!,
        intensity: intensity,
        activities: selectedActivities,
        triggers: selectedTriggers,
        date: DateTime.now(),
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      await StorageService.saveMoodEntry(entry);
      
      // Refresh data after saving
      await _loadInitialData();
      
      setState(() {
        isSaving = false;
        isSaved = true;
        // Clear form
        selectedMood = null;
        selectedActivities.clear();
        selectedTriggers.clear();
        intensity = 5;
        _noteController.clear();
        // Generate new smart suggestions
        _smartSuggestions = _generateSmartSuggestions();
      });

      HapticFeedback.mediumImpact();
      _showSnackBar('Entry saved successfully! 🌱');
      
      // Show celebration if streak milestone reached
      _showStreakCelebration();
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      _showSnackBar('Error saving entry. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final triggerOptions = const ['Work', 'Family', 'Health', 'Sleep', 'Money', 'Weather', 'Social', 'Diet'];
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getMoodColors(_currentMoodTheme).map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
        child: _isLoading
            ? _buildSkeletonLoader()
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      _buildModernAppBar(),
                      _buildSmartDashboard(),
                      _buildSmartSuggestionsSection(),
                      _buildDailyReminderSection(),
                      _buildQuickMoodSection(),
                      _buildDetailedMoodForm(),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: _buildQuickMoodFAB(),
    );
  }

  Widget _buildSkeletonLoader() {
    return CustomScrollView(
      slivers: [
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
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Dashboard skeleton
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 16),
                // Mood buttons skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildModernAppBar() {
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
                Colors.blue.shade400,
                Colors.purple.shade400,
                Colors.pink.shade400,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentGreeting,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How are you feeling today?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
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
      actions: [
        IconButton(
          tooltip: 'Weekly Review',
          icon: const Icon(Icons.analytics),
          onPressed: () => _safePush(const WeeklyReviewPage()),
        ),
        IconButton(
          tooltip: 'Timeline',
          icon: const Icon(Icons.history),
          onPressed: () => _safePush(const TimelinePage()),
        ),
        IconButton(
          tooltip: 'Daily Hub',
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _safePush(const DailyHubPage()),
        ),
        IconButton(
          tooltip: 'Habit Tracker',
          icon: const Icon(Icons.psychology),
          onPressed: _isNavigating ? null : () => _safePush(const HabitTrackerPage()),
        ),
        IconButton(
          tooltip: 'AI Insights',
          icon: const Icon(Icons.auto_awesome),
          onPressed: _isNavigating ? null : () => _safePush(const AIInsightsPage()),
        ),
        IconButton(
          tooltip: 'Schedule Test Notification',
          icon: const Icon(Icons.notifications_active),
          onPressed: () async {
            await NotificationService.scheduleInSeconds(
              title: 'Test Notification',
              body: 'This is a test notification from Bloom App!',
              seconds: 5,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test notification scheduled!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSmartDashboard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Today\'s Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Mood Streak',
                        '$_moodStreak days',
                        Icons.local_fire_department,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Today\'s Entries',
                        '${_recentMoods.length}',
                        Icons.today,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Last Mood',
                        _recentMoods.isNotEmpty ? _getMoodEmoji(_recentMoods.first.mood) : '😊',
                        Icons.mood,
                        Colors.green,
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

  Widget _buildSmartSuggestionsSection() {
    if (_smartSuggestions.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber.shade600, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Smart Suggestions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._smartSuggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReminderSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.alarm, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Mood Reminder', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        _reminderEnabled
                            ? 'Scheduled for ${_reminderTime.format(context)}'
                            : 'Get a gentle nudge to log your mood daily',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _reminderEnabled,
                  onChanged: (v) async {
                    setState(() => _reminderEnabled = v);
                    if (v) {
                      await NotificationService.scheduleDailyAt(
                        id: 42,
                        hour: _reminderTime.hour,
                        minute: _reminderTime.minute,
                        title: 'Bloom Reminder',
                        body: 'How are you feeling today? Tap to log 🌱',
                      );
                    } else {
                      await NotificationService.cancel(42);
                    }
                  },
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: !_reminderEnabled ? null : () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                      await NotificationService.scheduleDailyAt(
                        id: 42,
                        hour: picked.hour,
                        minute: picked.minute,
                        title: 'Bloom Reminder',
                        body: 'How are you feeling today? Tap to log 🌱',
                      );
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text('Time'),
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
              fontSize: 18,
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

  Widget _buildQuickMoodSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Quick Mood Check',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickMoodButton('😊', 'Happy', Colors.green),
                    _buildQuickMoodButton('😔', 'Sad', Colors.blue),
                    _buildQuickMoodButton('😡', 'Angry', Colors.red),
                    _buildQuickMoodButton('😌', 'Calm', Colors.purple),
                    _buildQuickMoodButton('😴', 'Tired', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMoodButton(String emoji, String mood, Color color) {
    final isSelected = selectedMood == mood;
    return GestureDetector(
      onTap: () => _selectMood(mood),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 3 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedMoodForm() {
    final triggerOptions = const ['Work', 'Family', 'Health', 'Sleep', 'Money', 'Weather', 'Social', 'Diet'];
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detailed Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Intensity slider
                if (selectedMood != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Intensity', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$intensity/10', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: intensity.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$intensity',
                      onChanged: (v) => setState(() => intensity = v.round()),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Activities
                const Text('Activities', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Work', 'Study', 'Exercise', 'Social', 'Rest', 'Creative'
                  ].map((activity) => _buildActivityChip(activity)).toList(),
                ),

                const SizedBox(height: 20),
                
                // Triggers
                const Text('What influenced your mood?', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: triggerOptions.map((trigger) => _buildTriggerChip(trigger)).toList(),
                ),

                const SizedBox(height: 20),
                
                // Note
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Why do you feel this way? (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                
                // Save button
                if (selectedMood != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isSaved ? 'Saved! 🌱' : 'Save Entry',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityChip(String activity) {
    final isSelected = selectedActivities.contains(activity);
    return FilterChip(
      label: Text(activity),
      selected: isSelected,
      onSelected: (_) => _toggleActivity(activity),
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildTriggerChip(String trigger) {
    final isSelected = selectedTriggers.contains(trigger);
    return FilterChip(
      label: Text(trigger),
      selected: isSelected,
      onSelected: (_) => _toggleTrigger(trigger),
      selectedColor: Colors.purple.withOpacity(0.2),
      checkmarkColor: Colors.purple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.purple.shade800 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildQuickMoodFAB() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Quick mood logging - could open a bottom sheet or navigate
              _showQuickMoodBottomSheet();
            },
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Quick Log', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  void _showQuickMoodBottomSheet() async {
    // Pause pulse animation for focus and performance while sheet is open
    _pulseController.stop();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Local state for ultra-fast tap feedback without rebuilding the whole page
        String? localSelectedMood = selectedMood;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Widget quickButton(String emoji, String mood, Color color) {
              final isSelected = localSelectedMood == mood;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setLocal(() => localSelectedMood = mood);
                  setState(() => selectedMood = mood);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Quick Mood Log',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Text('How are you feeling right now?'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            quickButton('😊', 'Happy', Colors.green),
                            quickButton('😔', 'Sad', Colors.blue),
                            quickButton('😡', 'Angry', Colors.red),
                            quickButton('😌', 'Calm', Colors.purple),
                            quickButton('😴', 'Tired', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: localSelectedMood != null ? () {
                              Navigator.pop(ctx);
                              _saveEntry();
                            } : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Log Mood', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // Resume pulse animation after sheet closes
    if (mounted) {
      _pulseController.repeat(reverse: true);
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'Happy': return '😊';
      case 'Sad': return '😔';
      case 'Angry': return '😡';
      case 'Calm': return '😌';
      case 'Tired': return '😴';
      default: return '😊';
    }
  }
}
