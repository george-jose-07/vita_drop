import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:vita_drop/screens/add_entry_screen.dart';
import 'package:vita_drop/screens/add_workout_screen.dart';
import 'package:vita_drop/screens/settings_screen.dart';
import 'package:vita_drop/widgets/drawer.dart' show MainDrawer;
import 'package:vita_drop/screens/dashboard/health_metrics_screen.dart';
import 'package:vita_drop/screens/dashboard/daily_progress_screen.dart';
import 'package:vita_drop/screens/dashboard/quick_actions_screen.dart';
import 'package:vita_drop/screens/dashboard/workout_screen.dart';

import '../../core/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Theme colors
  final Color backgroundColor1 = Color(0xFFF0F4F8);
  final Color darkBackgroundColor1 = Color(0xFF1A1F25);
  final Color backgroundColor2 = Color(0xFFD9E2EC);
  final Color darkBackgroundColor2 = Color(0xFF2C3A4B);
  final Color backgroundColor3 = Color(0xFFBCCCDC);
  final Color darkBackgroundColor3 = Color(0xFF3E4C59);
  final Color darkTextColor = Color(0xFFE4E7EB);
  final Color textColor = Color(0xFF243B53);
  final Color darkCardColor = Color(0xFF2A2F36);
  final Color cardColor = Color(0xFFF7FAFC);
  final Color darkAccentColor = Color(0xFF9AA5B1);
  final Color accentColor = Color(0xFF627D98);

  // User data
  String username = '';
  String bmi = '0';
  String bmiType = 'Unknown';
  double waterIntake = 0.0;
  int totalCalories = 0;
  int dailyCalorieGoal = 2000;
  double totalWater = 0.0;
  double dailyWaterGoal = 2.0;
  int totalCaloriesBurned = 0;
  int dailyCalorieBurnGoal = 500;
  List<Map<String, dynamic>> workoutEntries = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchUserData();
    await _fetchDailyData();
    await _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          dailyCalorieGoal = doc.data()?['daily_calorie_limit'] ?? 2000;
          dailyWaterGoal = (doc.data()?['daily_water_limit'] ?? 2000) / 1000.0;
          dailyCalorieBurnGoal = doc.data()?['daily_calorie_burn_goal'] ?? 500;
        });
      } else {
        print('User document does not exist. Creating default settings.');
        await _createDefaultSettings();
      }
    } catch (e) {
      print('Error fetching settings: $e');
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'daily_calorie_limit': 2000,
        'daily_water_limit': 2000,
        'daily_calorie_burn_goal': 500,
      });
      await _fetchSettings();
    } catch (e) {
      print('Error creating default settings: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          username = doc['username'] ?? 'User';
          bmi = doc['bmi']?.toString() ?? '0';
          bmiType = _getBMICategory(double.tryParse(bmi) ?? 0.0);
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchDailyData() async {
    try {
      // Fetch meals data
      final mealsDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(today)
          .get();

      if (mealsDoc.exists) {
        setState(() {
          totalCalories = mealsDoc['totalKcal'] ?? 0;
        });
      }

      // Fetch water data
      final waterDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('water')
          .doc(today)
          .get();

      if (waterDoc.exists) {
        final totalMl = waterDoc['total'] ?? 0;
        setState(() {
          totalWater = totalMl; // Keep in ml for storage
          waterIntake = totalMl / 1000.0; // Convert to L for display
        });
      }

      // Fetch workout data
      final workoutDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc(today)
          .get();

      if (workoutDoc.exists) {
        setState(() {
          totalCaloriesBurned = workoutDoc['total_calories_burned'] ?? 0;
        });
      }

      // Fetch workout entries
      final workoutSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc(today)
          .collection('entries')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        workoutEntries = workoutSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'type': data['type'],
            'calories_burned': data['calories_burned'],
            'duration': data['duration'],
            'notes': data['notes'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching daily data: $e');
    }
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi >= 18.5 && bmi < 25) return 'Normal weight';
    if (bmi >= 25 && bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // Future<void> _addMeal({
  //   required String name,
  //   required int calories,
  //   required String type,
  // }) async {
  //   try {
  //     final docRef = _firestore
  //         .collection('users')
  //         .doc(uid)
  //         .collection('meals')
  //         .doc(today);
  //
  //     // Add the meal entry
  //     await docRef.collection('entries').add({
  //       'name': name,
  //       'kcal': calories,
  //       'type': type,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //
  //     // Get current total
  //     final doc = await docRef.get();
  //     final currentTotal = doc.exists ? (doc.data()?['totalKcal'] ?? 0) : 0;
  //     final newTotal = currentTotal + calories;
  //
  //     // Update the total
  //     await docRef.set({
  //       'totalKcal': newTotal,
  //     }, SetOptions(merge: true));
  //
  //     // Update the state immediately after Firestore operation
  //     setState(() {
  //       totalCalories = newTotal; // Update state with new total
  //     });
  //
  //     // Show success message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Added $name: $calories kcal'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error adding meal: $e');
  //     // if (mounted) {
  //     //   ScaffoldMessenger.of(context).showSnackBar(
  //     //     SnackBar(content: Text('Error adding meal: ${e.toString()}')),
  //     //   );
  //     // }
  //   }
  // }
  //
  // Future<void> _addWorkout({
  //   required String name,
  //   required int caloriesBurned,
  //   required int duration,
  //   required String type,
  //   String? notes,
  // }) async {
  //   try {
  //     final docRef = _firestore
  //         .collection('users')
  //         .doc(uid)
  //         .collection('workouts')
  //         .doc(today);
  //
  //     // Add the workout entry
  //     await docRef.collection('entries').add({
  //       'name': name,
  //       'calories_burned': caloriesBurned,
  //       'duration': duration,
  //       'type': type,
  //       'notes': notes,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //
  //     // Get current total
  //     final doc = await docRef.get();
  //     final currentTotal =
  //         doc.exists ? (doc.data()?['total_calories_burned'] ?? 0) : 0;
  //     final newTotal = currentTotal + caloriesBurned;
  //
  //     // Update the total in both entries and daily total
  //     await docRef.set({
  //       'total_calories_burned': newTotal,
  //       'date': today,
  //       'last_updated': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //
  //     // Update the state immediately after Firestore operation
  //     setState(() {
  //       totalCaloriesBurned = newTotal; // Update state with new total
  //     });
  //
  //     // Show success message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Added $name: $caloriesBurned kcal burned'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error adding workout: $e');
  //     // if (mounted) {
  //     //   ScaffoldMessenger.of(context).showSnackBar(
  //     //     SnackBar(content: Text('Error adding workout: ${e.toString()}')),
  //     //   );
  //     // }
  //   }
  // }
  //
  // Future<void> _addWater(double amount) async {
  //   try {
  //     final docRef = _firestore
  //         .collection('users')
  //         .doc(uid)
  //         .collection('water')
  //         .doc(today);
  //
  //     // Convert liters to milliliters (1L = 1000ml)
  //     final amountInMl = (amount * 1000).toDouble();
  //
  //     // Add the water entry in milliliters
  //     await docRef.collection('entries').add({
  //       'amount': amountInMl,
  //       'timestamp': FieldValue.serverTimestamp(),
  //     });
  //
  //     // Get current total in milliliters
  //     final doc = await docRef.get();
  //     final currentTotal = doc.exists ? (doc.data()?['total'] ?? 0.0) : 0.0;
  //     final newTotal = currentTotal + amountInMl;
  //
  //     // Update the total in milliliters
  //     await docRef.set({
  //       'total': newTotal,
  //       'date': today,
  //       'last_updated': FieldValue.serverTimestamp(),
  //     }, SetOptions(merge: true));
  //
  //     // Update the state immediately after Firestore operation
  //     setState(() {
  //       totalWater = newTotal; // Update state with new total
  //       waterIntake = newTotal / 1000.0; // Convert to liters for display
  //     });
  //
  //     // Show success message in liters
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Added ${amount}L of water'),
  //         backgroundColor: Colors.blue,
  //       ),
  //     );
  //   } catch (e) {
  //     print('Error adding water: $e');
  //     // if (mounted) {
  //     //   ScaffoldMessenger.of(context).showSnackBar(
  //     //     SnackBar(content: Text('Error adding water: ${e.toString()}')),
  //     //   );
  //     // }
  //   }
  // }

  Future<void> _refreshData() async {
    await _fetchUserData();
    await _fetchDailyData();
    await _fetchSettings();
    await _buildDailyProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "VitaDrop",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
        ),
        backgroundColor: isDarkMode
            ? AppColors.darBackgroundColor1
            : AppColors.backgroundColor1,
        actions: [
          IconButton(
            icon: Icon(Icons.psychology_alt, size: 28),
            onPressed: () {
              print('Chatbot clicked');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onSettingsUpdated: _refreshData,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: MainDrawer(
          onSettingsUpdated: _refreshData,
        ),
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
                : [AppColors.backgroundColor1,
              AppColors.backgroundColor2,
              AppColors.backgroundColor3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildWelcomeSection(isDarkMode
                    ? AppColors.darkAccentColor
                    : AppColors.accentColor,isDarkMode
                    ? AppColors.darkTextColor
                    : AppColors.textColor),
                HealthMetricsScreen(
                  bmi: bmi,
                  bmiType: bmiType,
                  waterIntake: waterIntake,
                  textColor: isDarkMode
                      ? AppColors.darkTextColor
                      : AppColors.textColor,
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                ),
                _buildDailyProgress(),
                QuickActionsScreen(
                  textColor: isDarkMode ? darkTextColor : textColor,
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  onAddMeal: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEntryScreen(
                          entryType: 'meal',
                          onValueUpdated: _refreshData,
                        ),
                      ),
                    );
                  },
                  onAddWater: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEntryScreen(
                          entryType: 'water',
                          onValueUpdated: _refreshData,
                        ),
                      ),
                    );
                  },
                  onAddWorkout: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddWorkoutScreen(onSettingsUpdated: _refreshData),
                      ),
                    );
                  },
                ),
                WorkoutScreen(
                  workoutEntries: workoutEntries,
                  onSettingsUpdated: _refreshData,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
      Color accentColor, Color textColor
      ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 24,
              color: accentColor,
            ),
          ),
          Text(
            username,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress() {
    return DailyProgressScreen(
      totalCalories: totalCalories,
      totalWater: totalWater.toInt(),
      totalCaloriesBurned: totalCaloriesBurned,
      dailyCalorieLimit: dailyCalorieGoal,
      dailyWaterLimit: (dailyWaterGoal * 1000).toInt(),
      dailyCalorieBurnGoal: dailyCalorieBurnGoal,
    );
  }

  // @override
  // void dispose() {
  //   // Cancel any ongoing operations or listeners here if necessary
  //   super.dispose();
  // }
}
