// lib/screens/meal/components/meal_type_selector.dart
import 'package:flutter/material.dart';

class MealTypeSelector extends StatelessWidget {
  final String selectedTime;
  final Function(String) onTimeSelected;

  const MealTypeSelector({
    Key? key,
    required this.selectedTime,
    required this.onTimeSelected,
  }) : super(key: key);

  Widget _buildTimeButton({
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTimeButton(
            label: '아침',
            icon: Icons.wb_sunny_outlined,
            value: 'breakfast',
            isSelected: selectedTime == 'breakfast',
            onTap: () => onTimeSelected('breakfast'),
          ),
          _buildTimeButton(
            label: '점심',
            icon: Icons.wb_sunny,
            value: 'lunch',
            isSelected: selectedTime == 'lunch',
            onTap: () => onTimeSelected('lunch'),
          ),
          _buildTimeButton(
            label: '저녁',
            icon: Icons.nights_stay_outlined,
            value: 'dinner',
            isSelected: selectedTime == 'dinner',
            onTap: () => onTimeSelected('dinner'),
          ),
          _buildTimeButton(
            label: '간식',
            icon: Icons.restaurant_outlined,
            value: 'snack',
            isSelected: selectedTime == 'snack',
            onTap: () => onTimeSelected('snack'),
          ),
        ],
      ),
    );
  }
}
