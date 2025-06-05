import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> mealHistory = [];
  List<Map<String, dynamic>> todayMeals = [];
  double maxCalories = 0.0;
  int todayTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchMealHistory();
  }

  Future<void> _fetchMealHistory() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));
    final fifteenDaysAgoStr = DateFormat('yyyy-MM-dd').format(fifteenDaysAgo);

    try {
      // Fetch all meals and filter in memory
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .get();

      // Filter documents for the last 15 days
      final filteredDocs = querySnapshot.docs.where((doc) {
        final docDate = doc.id;
        return docDate.compareTo(fifteenDaysAgoStr) >= 0 &&
            docDate.compareTo(today) <= 0;
      }).toList()
        ..sort((a, b) => b.id.compareTo(a.id)); // Sort by date descending

      // Process all days data
      final List<Map<String, dynamic>> tempMealHistory =
          filteredDocs.map((doc) {
        final date = doc.id;
        final totalCalories = doc['totalKcal'] ?? 0;
        return {
          'date': date,
          'calories': totalCalories,
        };
      }).toList();

      // Get today's meals
      final todayDoc = filteredDocs.where((doc) => doc.id == today).firstOrNull;

      List<Map<String, dynamic>> tempTodayMeals = [];
      int tempTodayTotal = 0;

      if (todayDoc != null) {
        // Set today's total calories
        tempTodayTotal = todayDoc['totalKcal'] ?? 0;

        // Get individual meals for today
        final entriesSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('meals')
            .doc(today)
            .collection('entries')
            .orderBy('timestamp', descending: true)
            .get();

        tempTodayMeals = entriesSnapshot.docs.map((doc) {
          final data = doc.data();

          return {
            'name': data['name'],
            'calories': data['kcal'],
            'type': data['type'],
            'time': DateFormat('HH:mm').format(data['timestamp'].toDate()),
          };
        }).toList();
      }

      // Calculate max calories for graph scaling
      final double tempMaxCalories = tempMealHistory.isEmpty
          ? 2000.0
          : tempMealHistory
                  .map((e) => e['calories'].toDouble())
                  .reduce((a, b) => a > b ? a : b) +
              500.0;

      // Sort meal history by date in ascending order for the graph
      tempMealHistory.sort((a, b) => a['date'].compareTo(b['date']));

      setState(() {
        mealHistory = tempMealHistory;
        todayMeals = tempTodayMeals;
        todayTotal = tempTodayTotal;
        maxCalories = tempMaxCalories;
      });
    } catch (e) {
      print('Error fetching meal history: $e');
    }
  }

  // Add this function to the _MealHistoryScreenState class
  Future<void> _deleteMealEntry(
      Map<String, dynamic> meal, String time, bool isDark) async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    // Show confirmation dialog
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark
                ? AppColors.darBackgroundColor1
                : AppColors.backgroundColor1,
            title: Text(
              'Delete Meal',
              style: TextStyle(
                  color:
                      isDark ? AppColors.darkTextColor : AppColors.textColor),
            ),
            content: Text(
              'Are you sure you want to delete "${meal['name']}"?',
              style: TextStyle(
                  color:
                      isDark ? AppColors.darkTextColor : AppColors.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel',
                  style: TextStyle(
                      color:
                      isDark ? AppColors.darkTextColor : AppColors.textColor),),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      // Query to find the document with matching time and name
      final entriesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(today)
          .collection('entries')
          .where('name', isEqualTo: meal['name'])
          .get();

      // Find the specific entry that matches our time
      QueryDocumentSnapshot<Map<String, dynamic>>? entryToDelete;

      for (var doc in entriesSnapshot.docs) {
        final timestamp = doc.data()['timestamp'].toDate();
        final docTime = DateFormat('HH:mm').format(timestamp);
        if (docTime == time) {
          entryToDelete = doc;
          break;
        }
      }

      if (entryToDelete != null) {
        // Delete the entry
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('meals')
            .doc(today)
            .collection('entries')
            .doc(entryToDelete.id)
            .delete();

        // Update the total calories for today
        final newTotal = todayTotal - meal['calories'];
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('meals')
            .doc(today)
            .update({'totalKcal': newTotal});

        // Refresh the data
        _fetchMealHistory();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find the meal to delete')),
        );
      }
    } catch (e) {
      print('Error deleting meal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting meal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Meal History',
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
                    height: 250,
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
                        maxY: maxCalories,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toInt()} kcal',
                                TextStyle(
                                  color: isDarkMode
                                      ? AppColors.darkTextColor
                                      : AppColors.textColor,
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
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= mealHistory.length)
                                  return const Text('');
                                final date = mealHistory[value.toInt()]['date'];

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      DateFormat('MMM-d')
                                          .format(DateTime.parse(date)),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? AppColors.darkTextColor
                                            : AppColors.textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? AppColors.darkTextColor
                                        : AppColors.textColor,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          mealHistory.length,
                          (index) {
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY:
                                      mealHistory[index]['calories'].toDouble(),
                                  color: Colors.orange,
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Today's Meals",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
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
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_fire_department_outlined,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Today',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? AppColors.darkTextColor
                                        : AppColors.textColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$todayTotal kcal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? AppColors.darkTextColor
                                        : AppColors.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...todayMeals.map<Widget>((meal) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 20, bottom: 8),
                            child: GestureDetector(
                              onLongPress: () => _deleteMealEntry(
                                  meal, meal['time'], isDarkMode),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        meal['time'],
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? AppColors.darkTextColor
                                              : AppColors.textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          '${meal['name']} ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: isDarkMode
                                                ? AppColors.darkTextColor
                                                : AppColors.textColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),
                                      // Text(
                                      //   '• ${meal['calories']} kcal',
                                      //   style: TextStyle(
                                      //     fontSize: 14,
                                      //     fontWeight: FontWeight.w500,
                                      //     color: isDarkMode
                                      //         ? AppColors.darkTextColor
                                      //         : AppColors.textColor,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 60),
                                    child: Text(
                                      '${meal['type']}  •  ${meal['calories']} kcal',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? AppColors.darkTextColor
                                            : AppColors.textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
