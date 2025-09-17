import 'package:flutter/material.dart';

class MoodButton extends StatelessWidget {
  final String emoji;
  final String mood;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.emoji,
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
