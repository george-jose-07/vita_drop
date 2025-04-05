import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vita_drop/screens/dashboard/home_screen.dart';
import 'package:vita_drop/signup_page.dart';

import 'core/constants/colors.dart';

final _firebase = FirebaseAuth.instance;

class LogInPage extends StatefulWidget {
  final int initialPage;

  const LogInPage({super.key, this.initialPage = 0});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  late final PageController _pageController;

  bool _obscurePassword = true;

  var _enteredEmail = '';
  var _enteredPassword = '';
  final _form = GlobalKey<FormState>();
  var _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      //show error
      return;
    }
    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });

      final userCredentials = await _firebase.signInWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );
      print(userCredentials);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication failed'),
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
        body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: Form(
              key: _form,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 64),
                    Icon(
                      Icons.spa,
                      size: 120,
                      color: isDarkMode
                          ? AppColors.darkTextColor
                          : AppColors.textColor,
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains('@')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredEmail = value!;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.trim().length < 4) {
                          return 'Please enter a valid password.';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredPassword = value!;
                      },
                      obscureText: _obscurePassword,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? AppColors.darkCardColor
                            : AppColors.cardColor,
                        foregroundColor: isDarkMode
                            ? AppColors.darkAccentColor
                            : AppColors.accentColor,
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
                        'Sign In',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkAccentColor
                              : AppColors.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpPage()),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Sign Up',
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
        ),
      ),
    ));
  }
}
