import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vita_drop/core/constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSettingsUpdated;

  const SettingsScreen({
    super.key,
    required this.onSettingsUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  late TextEditingController _calorieLimitController;
  late TextEditingController _waterLimitController;
  late TextEditingController _calorieBurnGoalController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _calorieLimitController = TextEditingController();
    _waterLimitController = TextEditingController();
    _calorieBurnGoalController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _calorieLimitController.dispose();
    _waterLimitController.dispose();
    _calorieBurnGoalController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSettings() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        setState(() {
          _calorieLimitController.text =
              doc['daily_calorie_limit']?.toString() ?? '2000';
          _waterLimitController.text =
              ((doc['daily_water_limit'] ?? 2000) / 1000).toString();
          _calorieBurnGoalController.text =
              doc['daily_calorie_burn_goal']?.toString() ?? '500';
          _heightController.text = doc['height']?.toString() ?? '';
          _weightController.text = doc['weight']?.toString() ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Parse height and weight
      double height =
          double.parse(_heightController.text) / 100; // Convert cm to meters
      double weight = double.parse(_weightController.text);

      // Calculate BMI
      double bmi = weight / (height * height);

      await _firestore.collection('users').doc(uid).update({
        'daily_calorie_limit': int.parse(_calorieLimitController.text),
        'daily_water_limit':
            (double.parse(_waterLimitController.text) * 1000).round(),
        'daily_calorie_burn_goal': int.parse(_calorieBurnGoalController.text),
        'height': height * 100, // Store height in cm
        'weight': weight,
        'bmi': bmi, // Update BMI in Firestore
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
    widget.onSettingsUpdated();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
                _buildSettingCard(
                  title: 'Daily Calorie Limit',
                  icon: Icons.local_fire_department,
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  child: TextFormField(
                    controller: _calorieLimitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      suffixText: 'kcal',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      filled: true,
                      fillColor: isDarkMode
                          ? AppColors.innerDarkCardColor
                          : AppColors.innerCardColor,
                    ),
                    style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a calorie limit';
                      }
                      final calories = int.tryParse(value);
                      if (calories == null || calories <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingCard(
                  title: 'Daily Water Intake Goal',
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  icon: Icons.water_drop,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  child: TextFormField(
                    controller: _waterLimitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Water',
                      suffixText: 'L',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      filled: true,
                      fillColor: isDarkMode
                          ? AppColors.innerDarkCardColor
                          : AppColors.innerCardColor,
                    ),
                    style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a water intake goal';
                      }
                      final water = double.tryParse(value);
                      if (water == null || water <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingCard(
                  title: 'Daily Calorie Burn Goal',
                  icon: Icons.fitness_center,
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  child: TextFormField(
                    controller: _calorieBurnGoalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Calories to Burn',
                      suffixText: 'kcal',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      filled: true,
                      fillColor: isDarkMode
                          ? AppColors.innerDarkCardColor
                          : AppColors.innerCardColor,
                    ),
                    style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a calorie burn goal';
                      }
                      final calories = int.tryParse(value);
                      if (calories == null || calories <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingCard(
                  title: 'Height',
                  icon: Icons.height,
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Height',
                      suffixText: 'cm',
                      border: const OutlineInputBorder(),
                      labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      filled: true,
                      fillColor: isDarkMode
                          ? AppColors.innerDarkCardColor
                          : AppColors.innerCardColor,
                    ),
                    style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your height';
                      }
                      final height = double.tryParse(value);
                      if (height == null || height <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSettingCard(
                  title: 'Weight',
                  icon: Icons.monitor_weight,
                  cardColor: isDarkMode
                      ? AppColors.darkCardColor
                      : AppColors.cardColor,
                  accentColor: isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'kg',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: isDarkMode
                          ? AppColors.innerDarkCardColor
                          : AppColors.innerCardColor,
                      labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                      suffixStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor),
                    ),
                    style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your weight';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundColor2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save Settings',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard(
      {required String title,
      required IconData icon,
      required Color cardColor,
      required Widget child,
      required Color accentColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
