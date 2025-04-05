import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> workoutHistory = [];
  List<Map<String, dynamic>> todayWorkouts = [];
  double maxCaloriesBurned = 0.0;
  int todayTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutHistory();
  }

  Future<void> _fetchWorkoutHistory() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));

    // Fetch last 15 days data
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .where('date',
            isGreaterThanOrEqualTo:
                DateFormat('yyyy-MM-dd').format(fifteenDaysAgo))
        .orderBy('date', descending: true)
        .get();

    setState(() {
      // Process all days data
      workoutHistory = querySnapshot.docs.map((doc) {
        final date = doc['date'];
        final totalCalories = doc['total_calories_burned'] ?? 0;
        return {
          'date': date,
          'calories': totalCalories,
        };
      }).toList();

      // Get today's workouts
      final todayDoc =
          querySnapshot.docs.where((doc) => doc['date'] == today).firstOrNull;

      if (todayDoc != null) {
        todayTotal = todayDoc['total_calories_burned'] ?? 0;

        // Get individual workouts for today
        _firestore
            .collection('users')
            .doc(uid)
            .collection('workouts')
            .doc(today)
            .collection('entries')
            .orderBy('timestamp', descending: true)
            .get()
            .then((snapshot) {
          setState(() {
            todayWorkouts = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'name': data['name'],
                'calories': data['calories_burned'],
                'duration': data['duration'],
                'type': data['type'],
                'time': DateFormat('HH:mm').format(data['timestamp'].toDate()),
              };
            }).toList();
          });
        });
      } else {
        todayTotal = 0;
        todayWorkouts = [];
      }

      // Set max calories burned for graph scaling
      maxCaloriesBurned = workoutHistory.isEmpty
          ? 500.0
          : workoutHistory
                  .map((e) => e['calories'].toDouble())
                  .reduce((a, b) => a > b ? a : b) +
              100.0;

      // Sort workout history by date in ascending order for the graph
      workoutHistory.sort((a, b) => a['date'].compareTo(b['date']));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Workout History',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
        ),
        backgroundColor: isDarkMode
            ? AppColors.darBackgroundColor1
            : AppColors.backgroundColor1,
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
              AppColors.darBackgroundColor1,
              AppColors.darBackgroundColor2,
              AppColors.darBackgroundColor3
            ]
                : [
              AppColors.backgroundColor1,
              AppColors.backgroundColor2,
              AppColors.backgroundColor3
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkCardColor
                          : AppColors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxCaloriesBurned,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} kcal',
                                TextStyle(
                                  color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= workoutHistory.length)
                                  return const Text('');
                                final date =
                                    workoutHistory[value.toInt()]['date'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM d')
                                        .format(DateTime.parse(date)),
                                    style: TextStyle(
                                      color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          workoutHistory.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: workoutHistory[index]['calories']
                                    .toDouble(),
                                color: const Color(0xFF4CAF50),
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Today's Workouts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkCardColor
                          : AppColors.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Today',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$todayTotal kcal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...todayWorkouts.map<Widget>((workout) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 40, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      workout['time'],
                                      style: TextStyle(
                                        color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      workout['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 60),
                                  child: Text(
                                    '${workout['calories']} kcal • ${workout['duration']} min • ${workout['type']}',
                                    style: TextStyle(
                                      color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
