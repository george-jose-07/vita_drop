import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';

class WaterHistoryScreen extends StatefulWidget {
  const WaterHistoryScreen({super.key});

  @override
  State<WaterHistoryScreen> createState() => _WaterHistoryScreenState();
}

class _WaterHistoryScreenState extends State<WaterHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> waterHistory = [];
  List<Map<String, dynamic>> todayEntries = [];
  double maxWaterIntake = 0.0;
  double todayTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWaterHistory();
  }

  Future<void> _fetchWaterHistory() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));

    // Fetch last 15 days data
    final querySnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('water')
        .where('date',
            isGreaterThanOrEqualTo:
                DateFormat('yyyy-MM-dd').format(fifteenDaysAgo))
        .orderBy('date', descending: true)
        .get();

    setState(() {
      // Process all days data
      waterHistory = querySnapshot.docs.map((doc) {
        final date = doc['date'];
        final totalMl = doc['total'] ?? 0;
        final totalL = totalMl / 1000.0;
        return {
          'date': date,
          'amount': totalL,
        };
      }).toList();

      // Get today's entries
      final todayDoc =
          querySnapshot.docs.where((doc) => doc['date'] == today).firstOrNull;

      if (todayDoc != null) {
        todayTotal = (todayDoc['total'] ?? 0) / 1000.0;

        // Get individual entries for today
        final entriesSnapshot = _firestore
            .collection('users')
            .doc(uid)
            .collection('water')
            .doc(today)
            .collection('entries')
            .orderBy('timestamp', descending: true)
            .get();

        entriesSnapshot.then((snapshot) {
          setState(() {
            todayEntries = snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'time': DateFormat('HH:mm').format(data['timestamp'].toDate()),
                'amount': (data['amount'] ?? 0) / 1000.0,
              };
            }).toList();
          });
        });
      } else {
        todayTotal = 0.0;
        todayEntries = [];
      }

      // Set max water intake for graph scaling
      maxWaterIntake = waterHistory.isEmpty
          ? 3.0
          : waterHistory
                  .map((e) => e['amount'])
                  .reduce((a, b) => a > b ? a : b) +
              1.0;

      // Sort water history by date in ascending order for the graph
      waterHistory.sort((a, b) => a['date'].compareTo(b['date']));
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
          'Water History',
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
                        maxY: maxWaterIntake,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toStringAsFixed(2)}L',
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
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= waterHistory.length)
                                  return const Text('');
                                final date = waterHistory[value.toInt()]['date'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM d')
                                        .format(DateTime.parse(date)),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? AppColors.darkTextColor
                                          : AppColors.textColor,
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
                                  '${value.toInt()}L',
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
                          waterHistory.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: waterHistory[index]['amount'],
                                color: Color(0xFF5cb5e1),
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
                    "Today's Water Intake",
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
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: Color(0xFF5cb5e1),
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
                                  '${todayTotal.toStringAsFixed(2)}L',
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
                        ...todayEntries.map<Widget>((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 40, bottom: 8),
                            child: Row(
                              children: [
                                Text(
                                  entry['time'],
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? AppColors.darkTextColor
                                        : AppColors.textColor,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${entry['amount'].toStringAsFixed(2)}L',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode
                                        ? AppColors.darkTextColor
                                        : AppColors.textColor,
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
