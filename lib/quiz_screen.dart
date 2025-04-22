import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vita_drop/screens/dashboard/home_screen.dart';

import 'core/constants/colors.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, dynamic> _answers = {};

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is your age?',
      'type': 'number',
      'hint': 'Enter your age',
    },
    {
      'question': 'What is your gender?',
      'type': 'radio',
      'options': ['Male', 'Female', 'Other'],
    },
    {
      'question': 'What is your height?',
      'type': 'measurement',
      'units': ['cm'],
    },
    {
      'question': 'What is your weight?',
      'type': 'measurement',
      'units': ['kg'],
    },
    {
      'question': 'How active are you?',
      'type': 'radio',
      'options': [
        'Sedentary (little or no exercise)',
        'Lightly active (1–3 days of light exercise)',
        'Moderately active (3–5 days of moderate exercise)',
        'Very active (6–7 days of hard exercise)',
        'Super active (intense training, sports, or physical job)',
      ],
    },
    {
      'question': 'What is your goal?',
      'type': 'radio',
      'options': [
        'Lose weight',
        'Maintain weight',
        'Gain muscle',
      ],
    },
    {
      'question': 'How many hours do you sleep on average per night?',
      'type': 'number',
      'hint': 'Enter hours of sleep',
    },
    {
      'question': 'Do you have any dietary restrictions?',
      'type': 'checkbox',
      'options': [
        'Vegetarian',
        'Vegan',
        'Gluten-free',
        'Dairy-free',
        'Nut allergy',
        'No restrictions',
      ],
    },
    {
      'question': 'How many meals do you prefer to eat in a day?',
      'type': 'radio',
      'options': ['2', '3', '4', '5+'],
    },
    {
      'question': 'How much water do you drink daily?',
      'type': 'measurement',
      'units': ['glasses', 'liters'],
    },
    {
      'question': 'Do you have any medical conditions we should consider?',
      'type': 'text',
      'hint': 'Enter medical conditions (if any)',
    },
    {
      'question':
          'Are you currently following a specific diet or fitness program?',
      'type': 'boolean',
      'followUp': 'text',
      'hint': 'Enter program details',
    },
    {
      'question': 'How intense do you want your workout recommendations to be?',
      'type': 'radio',
      'options': [
        'Light (Walking, Yoga, Stretching)',
        'Moderate (Running, Strength Training)',
        'Intense (HIIT, Weightlifting)',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "Profile Setup",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              LinearProgressIndicator(
                value: (_currentPage + 1) / questions.length,
                backgroundColor:
                    isDarkMode ? AppColors.darkCardColor : AppColors.cardColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode
                      ? AppColors.darkAccentColor
                      : AppColors.accentColor,
                ),
              ),

              // Questions
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: questions.length,
                  onPageChanged: (int page) {
                    setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) {
                    return _buildQuestionCard(
                        questions[index],
                        isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                        isDarkMode
                            ? AppColors.darkAccentColor
                            : AppColors.accentColor
                    );
                  },
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? AppColors.darkCardColor
                              : AppColors.cardColor,
                          foregroundColor: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        onPressed: _previousPage,
                        child: Text('Previous'),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        foregroundColor: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      onPressed: _nextPage,
                      child: Text(_currentPage == questions.length - 1
                          ? 'Finish'
                          : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
      Map<String, dynamic> question, Color cardColor, Color textColor, Color accentColor) {
    return SingleChildScrollView(
      child: Card(
        margin: EdgeInsets.all(20),
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question['question'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 20),
              _buildInputWidget(question,cardColor,textColor,accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputWidget(Map<String, dynamic> question, Color cardColor,
      Color textColor, Color accentColor) {
    switch (question['type']) {
      case 'number':
        return TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: question['hint'],
            hintStyle: TextStyle(color: accentColor.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
          ),
          onChanged: (value) {
            _answers[question['question']] = value;
          },
        );

      case 'radio':
        return Column(
          children: question['options'].map<Widget>((option) {
            return RadioListTile(
              title: Text(option, style: TextStyle(color: textColor)),
              value: option,
              groupValue: _answers[question['question']],
              activeColor: accentColor,
              onChanged: (value) {
                setState(() {
                  _answers[question['question']] = value;
                });
              },
            );
          }).toList(),
        );

      case 'checkbox':
        return Column(
          children: question['options'].map<Widget>((option) {
            return CheckboxListTile(
              title: Text(option, style: TextStyle(color: textColor)),
              value: (_answers[question['question']] ?? []).contains(option),
              activeColor: accentColor,
              onChanged: (bool? value) {
                setState(() {
                  if (_answers[question['question']] == null) {
                    _answers[question['question']] = [];
                  }
                  if (value!) {
                    _answers[question['question']].add(option);
                  } else {
                    _answers[question['question']].remove(option);
                  }
                });
              },
            );
          }).toList(),
        );

      case 'measurement':
        return Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter value',
                hintStyle: TextStyle(color: accentColor.withOpacity(0.5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accentColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: accentColor),
                ),
              ),
              onChanged: (value) {
                _answers[question['question']] = value;
              },
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _answers[question['question'] + '_unit'],
              hint: Text('Select unit', style: TextStyle(color: accentColor)),
              items: question['units']
                  .map<DropdownMenuItem<String>>((String unit) {
                return DropdownMenuItem<String>(
                  value: unit,
                  child: Text(unit, style: TextStyle(color: textColor)),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _answers[question['question'] + '_unit'] = value;
                });
              },
              style: TextStyle(color: textColor),
              dropdownColor: cardColor,
            ),
          ],
        );

      case 'boolean':
        return Column(
          children: [
            SwitchListTile(
              title: Text('No/Yes', style: TextStyle(color: textColor)),
              value: _answers[question['question']] ?? false,
              activeColor: accentColor,
              inactiveTrackColor: accentColor,
              onChanged: (bool value) {
                setState(() {
                  _answers[question['question']] = value;
                });
              },
            ),
            if ((_answers[question['question']] ?? false) &&
                question['followUp'] == 'text')
              TextField(
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: question['hint'],
                  hintStyle: TextStyle(color: accentColor.withOpacity(0.5)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accentColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: accentColor),
                  ),
                ),
                onChanged: (value) {
                  _answers[question['question'] + '_details'] = value;
                },
              ),
          ],
        );

      default:
        return TextField(
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: question['hint'],
            hintStyle: TextStyle(color: accentColor.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
          ),
          onChanged: (value) {
            _answers[question['question']] = value;
          },
        );
    }
  }

  void _saveAnswers() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    final weight = int.parse(_answers[questions[3]['question']]);
    final height = int.parse(_answers[questions[2]['question']]);
    final bmi = weight / ((height / 100) * (height / 100));
    try {
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'bmi': bmi.toStringAsFixed(2),
        'age': _answers[questions[0]['question']],
        'gender': _answers[questions[1]['question']],
        'height': height,
        //"${_answers[questions[2]['question']]} ${_answers[questions[2]['question'] + '_unit']}",
        'weight': weight,
        //"${_answers[questions[3]['question']]} ${_answers[questions[3]['question'] + '_unit']}",
        'activity': _answers[questions[4]['question']],
        'goal': _answers[questions[5]['question']],
        'sleep': _answers[questions[6]['question']],
        'diet': _answers[questions[7]['question']],
        'meals': _answers[questions[8]['question']],
        'water':
        "${_answers[questions[9]['question']]} ${_answers[questions[9]['question'] + '_unit']}",
        'medical': _answers[questions[10]['question']],
        'program':
        "${_answers[questions[11]['question']]} ${_answers[questions[11]['question'] + '_details']}",
        'workout': _answers[questions[12]['question']],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Height and weight updated successfully!')),
      );
    } catch (e) {
      print('Error saving answers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: ${e.toString()}')),
      );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < questions.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveAnswers();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
