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

  // Add this function to the _WaterHistoryScreenState class
  Future<void> _deleteWaterEntry(
      Map<String, dynamic> entry, String time, bool isDark) async {
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
              'Delete Water Entry',
              style: TextStyle(
                  color:
                      isDark ? AppColors.darkTextColor : AppColors.textColor),
            ),
            content: Text(
              'Are you sure you want to delete ${entry['amount'].toStringAsFixed(2)}L water entry?',
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
      // Query to find the document with matching time
      final entriesSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('water')
          .doc(today)
          .collection('entries')
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
        // Get the amount in ml to subtract from total
        final amountInMl = entryToDelete.data()['amount'] ?? 0;

        // Delete the entry
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('water')
            .doc(today)
            .collection('entries')
            .doc(entryToDelete.id)
            .delete();

        // Get the current total
        final docSnapshot = await _firestore
            .collection('users')
            .doc(uid)
            .collection('water')
            .doc(today)
            .get();

        final currentTotal = docSnapshot.data()?['total'] ?? 0;

        // Update the total water intake for today
        final newTotal = currentTotal - amountInMl;
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('water')
            .doc(today)
            .update({'total': newTotal});

        // Refresh the data
        _fetchWaterHistory();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Water entry deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not find the water entry to delete')),
        );
      }
    } catch (e) {
      print('Error deleting water entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting water entry')),
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
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= waterHistory.length)
                                  return const Text('');
                                final date =
                                    waterHistory[value.toInt()]['date'];
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
                                Icons.water_drop_outlined,
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
                            padding: const EdgeInsets.only(left: 20, bottom: 8),
                            child: GestureDetector(
                              onLongPress: () => _deleteWaterEntry(
                                  entry, entry['time'], isDarkMode),
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
