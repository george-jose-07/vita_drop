import 'package:flutter/material.dart';
import 'package:vita_drop/screens/meal_history_screen.dart';
import 'package:vita_drop/screens/water_history_screen.dart';
import 'package:vita_drop/screens/workout_history_screen.dart';

import '../../core/constants/colors.dart';

class DailyProgressScreen extends StatefulWidget {
  const DailyProgressScreen({
    super.key,
    required this.totalCalories,
    required this.totalWater,
    required this.totalCaloriesBurned,
    required this.dailyCalorieLimit,
    required this.dailyWaterLimit,
    required this.dailyCalorieBurnGoal,
  });

  final int totalCalories;
  final int totalWater;
  final int totalCaloriesBurned;
  final int dailyCalorieLimit;
  final int dailyWaterLimit;
  final int dailyCalorieBurnGoal;

  @override
  State<DailyProgressScreen> createState() => _DailyProgressScreenState();
}

class _DailyProgressScreenState extends State<DailyProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode?AppColors.darkTextColor:AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode?AppColors.darkCardColor:AppColors.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProgressCard(
                    title: 'Calories Consumed',
                    current: widget.totalCalories,
                    goal: widget.dailyCalorieLimit,
                    unit: 'kcal',
                    icon: Icons.local_fire_department_outlined,
                    color: Colors.orange,
                    textColor: isDarkMode?AppColors.darkTextColor:AppColors.textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MealHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(
                    title: 'Water Intake',
                    current: widget.totalWater,
                    goal: widget.dailyWaterLimit,
                    unit: 'ml',
                    icon: Icons.water_drop_outlined,
                    color: Color(0xFF5cb5e1),
                    textColor: isDarkMode?AppColors.darkTextColor:AppColors.textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WaterHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(
                    title: 'Calories Burned',
                    current: widget.totalCaloriesBurned,
                    goal: widget.dailyCalorieBurnGoal,
                    unit: 'kcal',
                    icon: Icons.fitness_center_outlined,
                    color: widget.totalCaloriesBurned >=
                            widget.dailyCalorieBurnGoal
                        ? Colors.green
                        : Colors.orange,
                    textColor: isDarkMode?AppColors.darkTextColor:AppColors.textColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required int current,
    required int goal,
    required String unit,
    required IconData icon,
    required Color color,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    final progress = goal > 0 ? current / goal : 0.0;
    final percentage = (progress * 100).toStringAsFixed(1);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Text(
                '$current / $goal $unit',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '$percentage% of daily goal',
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
