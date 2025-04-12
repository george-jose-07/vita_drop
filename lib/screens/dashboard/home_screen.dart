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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Staggered animations for sections
  late Animation<double> _welcomeAnimation;
  late Animation<double> _healthMetricsAnimation;
  late Animation<double> _dailyProgressAnimation;
  late Animation<double> _quickActionsAnimation;
  late Animation<double> _workoutAnimation;

  // Refresh animation
  bool _isRefreshing = false;

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

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Main fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Main slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Staggered section animations
    _welcomeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _healthMetricsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    ));

    _dailyProgressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    ));

    _quickActionsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
    ));

    _workoutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _loadInitialData();
    // Start animation after loading initial data
    _animationController.forward();
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

  Future<void> _refreshData() async {
    // Start refresh animation
    // setState(() {
    //   _isRefreshing = true;
    // });
    //
    // // Reset and replay animations
    // _animationController.reset();

    await _fetchUserData();
    await _fetchDailyData();
    await _fetchSettings();
    await _buildDailyProgress();

    // Forward animation after refresh
    // _animationController.forward();
    //
    // // End refresh animation
    // setState(() {
    //   _isRefreshing = false;
    // });
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
          AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _isRefreshing ? _animationController.value * 6.28 : 0,
                  child: IconButton(
                      icon: Icon(Icons.refresh, size: 28),
                      onPressed: _isRefreshing ? null : _refreshData
                  ),
                );
              }
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
              ).then((_) {
                // Replay animations when returning from settings
                _animationController.reset();
                _animationController.forward();
              });
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
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _welcomeAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.2, 0),
                              end: Offset.zero,
                            ).animate(_welcomeAnimation),
                            child: _buildWelcomeSection(
                              isDarkMode ? AppColors.darkAccentColor : AppColors.accentColor,
                              isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _healthMetricsAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(_healthMetricsAnimation),
                            child: HealthMetricsScreen(
                              bmi: bmi,
                              bmiType: bmiType,
                              waterIntake: waterIntake,
                              textColor: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                              accentColor: isDarkMode ? AppColors.darkAccentColor : AppColors.accentColor,
                              cardColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _dailyProgressAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.2, 0),
                              end: Offset.zero,
                            ).animate(_dailyProgressAnimation),
                            child: _buildDailyProgress(),
                          ),
                        ),
                        FadeTransition(
                          opacity: _quickActionsAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(_quickActionsAnimation),
                            child: QuickActionsScreen(
                              textColor: isDarkMode ? darkTextColor : textColor,
                              accentColor: isDarkMode ? AppColors.darkAccentColor : AppColors.accentColor,
                              cardColor: isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                              onAddMeal: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => AddEntryScreen(
                                      entryType: 'meal',
                                      onValueUpdated: _refreshData,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      var begin = const Offset(1.0, 0.0);
                                      var end = Offset.zero;
                                      var curve = Curves.easeInOut;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                ).then((_) {
                                  // Replay animations when returning
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                              onAddWater: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => AddEntryScreen(
                                      entryType: 'water',
                                      onValueUpdated: _refreshData,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      var begin = const Offset(1.0, 0.0);
                                      var end = Offset.zero;
                                      var curve = Curves.easeInOut;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                ).then((_) {
                                  // Replay animations when returning
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                              onAddWorkout: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => AddWorkoutScreen(
                                      onSettingsUpdated: _refreshData,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      var begin = const Offset(1.0, 0.0);
                                      var end = Offset.zero;
                                      var curve = Curves.easeInOut;
                                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                      return SlideTransition(
                                        position: animation.drive(tween),
                                        child: child,
                                      );
                                    },
                                  ),
                                ).then((_) {
                                  // Replay animations when returning
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _workoutAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(_workoutAnimation),
                            child: WorkoutScreen(
                              workoutEntries: workoutEntries,
                              onSettingsUpdated: _refreshData,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
          AnimatedBuilder(
              animation: _welcomeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.9 + (_welcomeAnimation.value * 0.1),
                  child: Text(
                    username,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                );
              }
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

  @override
  void dispose() {
    // Dispose animation controllers
    _animationController.dispose();
    super.dispose();
  }
}