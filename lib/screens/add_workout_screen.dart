import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';

class AddWorkoutScreen extends StatefulWidget {
  final VoidCallback onSettingsUpdated;
  const AddWorkoutScreen({Key? key, required this.onSettingsUpdated})
      : super(key: key);

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Cardio';
  int totalCaloriesBurned = 0;

  final List<String> _workoutTypes = [
    'Cardio',
    'Strength',
    'Flexibility',
    'HIIT',
    'Yoga',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Future<void> _submitWorkout() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   try {
  //     await _workoutService.addWorkout(
  //       name: _nameController.text,
  //       caloriesBurned: double.parse(_caloriesController.text),
  //       duration: int.parse(_durationController.text),
  //       type: _selectedType,
  //       notes: _notesController.text.isEmpty ? null : _notesController.text,
  //     );
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Workout added successfully!')),
  //       );
  //       Navigator.pop(context);
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error adding workout: ${e.toString()}')),
  //       );
  //     }
  //   }
  // }

  Future<void> _addWorkout({
    required String name,
    required int caloriesBurned,
    required int duration,
    required String type,
    String? notes,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .doc(today);

      // Add the workout entry
      await docRef.collection('entries').add({
        'name': name,
        'calories_burned': caloriesBurned,
        'duration': duration,
        'type': type,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get current total
      final doc = await docRef.get();
      final currentTotal = (doc.data()?['total_calories_burned'] ?? 0);
      final newTotal = currentTotal + caloriesBurned;

      // Update the total in both entries and daily total
      await docRef.set({
        'total_calories_burned': newTotal,
        'date': today,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update the state immediately after Firestore operation
      setState(() {
        totalCaloriesBurned = newTotal; // Update state with new total
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name: $caloriesBurned kcal burned'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding workout: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error adding workout: ${e.toString()}')),
      //   );
      // }
    }
    widget.onSettingsUpdated;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Workout',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
          ),
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor),
                  decoration: InputDecoration(
                    labelText: 'Workout Name',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a workout name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Workout Type',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: _workoutTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _caloriesController,
                  style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor),
                  decoration: InputDecoration(
                      labelText: 'Calories Burned',
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      border: const OutlineInputBorder(),
                      suffixText: 'kcal',
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor)),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter calories burned';
                    }
                    final number = double.tryParse(value);
                    if (number == null) {
                      return 'Please enter a valid number';
                    }
                    if (number <= 0) {
                      return 'Calories must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor),
                  decoration: InputDecoration(
                      labelText: 'Duration',
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      border: const OutlineInputBorder(),
                      suffixText: 'minutes',
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor)),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter duration';
                    }
                    final number = int.tryParse(value);
                    if (number == null) {
                      return 'Please enter a valid number';
                    }
                    if (number <= 0) {
                      return 'Duration must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor),
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    labelStyle: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _addWorkout(
                        name: _nameController.text,
                        caloriesBurned: int.parse(_caloriesController.text),
                        duration: int.parse(_durationController.text),
                        type: _selectedType,
                        notes: _notesController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? AppColors.darkCardColor
                        : AppColors.cardColor,
                    foregroundColor: isDarkMode
                        ? AppColors.darkTextColor
                        : AppColors.textColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                  ),
                  child: Text(
                    'Add Workout',
                    style: TextStyle(
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
