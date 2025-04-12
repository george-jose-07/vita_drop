import 'package:flutter/material.dart';
import 'package:vita_drop/screens/add_workout_screen.dart';

import '../../core/constants/colors.dart';

class WorkoutScreen extends StatelessWidget {
  final VoidCallback onSettingsUpdated;
  final List<Map<String, dynamic>> workoutEntries;

  const WorkoutScreen({
    Key? key,
    required this.workoutEntries,
    required this.onSettingsUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Workouts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                ),
              ],
            ),
          ),
          if (workoutEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: isDarkMode
                          ? AppColors.darkAccentColor
                          : AppColors.accentColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No workouts recorded today',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddWorkoutScreen(
                                  onSettingsUpdated: onSettingsUpdated),
                            ));
                      },
                      child: Text(
                        'Start your first workout',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkAccentColor
                              : AppColors.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: workoutEntries.length,
                itemBuilder: (context, index) {
                  final workout = workoutEntries[index];
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.innerDarkCardColor
                          : AppColors.innerCardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.innerDarkCardBorderColor
                            : AppColors.innerCardBorderColor,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkCardColor
                              : AppColors.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getWorkoutIcon(workout['type']),
                          color: isDarkMode
                              ? AppColors.darkAccentColor
                              : AppColors.accentColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        workout['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workout['calories_burned']} kcal',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workout['duration']} min',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // if (workout['notes'] != null &&
                          //     workout['notes'].isNotEmpty)
                          //   Padding(
                          //     padding: const EdgeInsets.only(top: 8),
                          //     child: Text(
                          //       workout['notes'],
                          //       style: TextStyle(
                          //         color: Colors.grey[600],
                          //         fontStyle: FontStyle.italic,
                          //       ),
                          //     ),
                          //   ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? AppColors.darkCardColor
                              : AppColors.cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          workout['type'],
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkAccentColor
                                : AppColors.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  IconData _getWorkoutIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.self_improvement;
      case 'hiit':
        return Icons.timer;
      case 'yoga':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }
}
