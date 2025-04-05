import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/constants/colors.dart';

class AddEntryScreen extends StatefulWidget {
  final String entryType;
  final VoidCallback onValueUpdated; // 'meal' or 'water'

  const AddEntryScreen(
      {Key? key, required this.entryType, required this.onValueUpdated})
      : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  // Meal form fields
  final _mealNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  String _selectedMealType = 'breakfast';

  double waterIntake = 0.0;
  int totalCalories = 0;
  double totalWater = 0.0;

  // Water form fields
  final _waterAmountController = TextEditingController();

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _waterAmountController.dispose();
    super.dispose();
  }

  Future<void> _addMeal({
    required String name,
    required int calories,
    required String type,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(today);

      // Add the meal entry
      await docRef.collection('entries').add({
        'name': name,
        'kcal': calories,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get current total
      final doc = await docRef.get();
      final currentTotal = (doc.data()?['totalKcal'] ?? 0);
      final newTotal = currentTotal + calories;

      // Update the total
      await docRef.set({
        'totalKcal': newTotal,
      }, SetOptions(merge: true));

      // Update the state immediately after Firestore operation
      setState(() {
        totalCalories = newTotal; // Update state with new total
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name: $calories kcal'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding meal: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error adding meal: ${e.toString()}')),
      //   );
      // }
    }
    widget.onValueUpdated;
    Navigator.pop(context);
  }

  Future<void> _addWater(double amount) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('water')
          .doc(today);

      // Convert liters to milliliters (1L = 1000ml)
      final amountInMl = (amount * 1000).toDouble();

      // Add the water entry in milliliters
      await docRef.collection('entries').add({
        'amount': amountInMl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Get current total in milliliters
      final doc = await docRef.get();
      final currentTotal = (doc.data()?['total'] ?? 0.0);
      final newTotal = currentTotal + amountInMl;

      // Update the total in milliliters
      await docRef.set({
        'total': newTotal,
        'date': today,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update the state immediately after Firestore operation
      setState(() {
        totalWater = newTotal; // Update state with new total
        waterIntake = newTotal / 1000.0; // Convert to liters for display
      });

      // Show success message in liters
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${amount}L of water'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error adding water: $e');
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error adding water: ${e.toString()}')),
      //   );
      // }
    }
    widget.onValueUpdated;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add ${widget.entryType == 'meal' ? 'Meal' : 'Water'}',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: widget.entryType == 'meal'
                ? _buildMealForm(
                    isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                    isDarkMode ? AppColors.darkCardColor : AppColors.cardColor)
                : _buildWaterForm(
                    isDarkMode ? AppColors.darkTextColor : AppColors.textColor,
                    isDarkMode ? AppColors.darkCardColor : AppColors.cardColor),
          ),
        ),
      ),
    );
  }

  Widget _buildMealForm(Color textColor, Color cardColor) {
    return ListView(
      children: [
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _mealNameController,
          decoration: InputDecoration(
            labelText: 'Meal Name',
            labelStyle: TextStyle(color: textColor),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a meal name';
            }
            return null;
          },

        ),
        const SizedBox(height: 16),
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _caloriesController,
          decoration: InputDecoration(
            labelText: 'Calories',
            labelStyle: TextStyle(color: textColor),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter calories';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          dropdownColor: cardColor,
          value: _selectedMealType,
          decoration: InputDecoration(
            labelText: 'Meal Type',
            labelStyle: TextStyle(color: textColor),
            border: const OutlineInputBorder(),
          ),
          items: ['breakfast', 'lunch', 'dinner', 'snack']
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.capitalize(),
                      style: TextStyle(color: textColor),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedMealType = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            _addMeal(
                name: _mealNameController.text,
                calories: int.parse(_caloriesController.text),
                type: _selectedMealType);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cardColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          child: Text(
            'Add Meal',
            style: TextStyle(
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaterForm(Color textColor, Color cardColor) {
    return ListView(
      children: [
        TextFormField(
          style: TextStyle(color: textColor),
          controller: _waterAmountController,
          decoration: InputDecoration(
            labelText: 'Water Amount (L)',
            labelStyle: TextStyle(color: textColor),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter water amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            _addWater(double.parse(_waterAmountController.text));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: cardColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          child: Text(
            'Add Water',
            style: TextStyle(
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
