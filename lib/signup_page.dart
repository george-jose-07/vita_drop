import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vita_drop/quiz_screen.dart';
import 'core/constants/colors.dart';
import 'login_page.dart';

final _firebase = FirebaseAuth.instance;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  final _form = GlobalKey<FormState>();
  var _isAuthenticating = false;
  var _enteredUsername = '';

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
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
      final userCredentials = await _firebase.createUserWithEmailAndPassword(
        email: _enteredEmail,
        password: _enteredPassword,
      );
      print(userCredentials);
      String uid = userCredentials.user!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
            'username': _enteredUsername,
            'email': _enteredEmail,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //....
      }
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
            child: SingleChildScrollView(
              child: Center(
                child: Form(
                  key: _form,
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
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            color: isDarkMode
                                ? AppColors.darkTextColor
                                : AppColors.textColor,
                          ),
                          prefixIcon: Icon(
                            Icons.person_2_outlined,
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
                          if (value == null || value.trim().length < 4) {
                            return 'Username must be at least 4 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredUsername = value!;
                        },
                        keyboardType: TextInputType.name,
                      ),
                      // _buildTextField(
                      //     label: 'Full Name', icon: Icons.person_outline),
                      const SizedBox(height: 24),
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
                      // _buildTextField(label: 'Email', icon: Icons.email_outlined),
                      const SizedBox(height: 24),
                      TextFormField(
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
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
                          suffixIcon: IconButton(
                            onPressed: _togglePasswordVisibility,
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: isDarkMode
                                  ? AppColors.darkTextColor
                                  : AppColors.textColor,
                            ),
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
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredPassword = value!;
                        },
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        obscureText: _obscureConfirmPassword,
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
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
                          suffixIcon: IconButton(
                            onPressed: _toggleConfirmPasswordVisibility,
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: isDarkMode
                                  ? AppColors.darkTextColor
                                  : AppColors.textColor,
                            ),
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
                          if (value == null || value.trim().length < 6) {
                            return 'Password must be at least 6 characters long.';
                          }
                          // if(value!=_enteredPassword){
                          //   return 'Password is not same';
                          // }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredPassword = value!;
                        },
                        keyboardType: TextInputType.text,
                      ),
                      // // _buildPasswordField(
                      // //   label: 'Password',
                      // //   icon: Icons.lock_outline,
                      // //   obscureText: _obscurePassword,
                      // //   onToggleVisibility: _togglePasswordVisibility,
                      // // ),
                      // _buildPasswordField(
                      //   label: 'Confirm Password',
                      //   icon: Icons.lock_outline,
                      //   obscureText: _obscureConfirmPassword,
                      //   onToggleVisibility: _toggleConfirmPasswordVisibility,
                      // ),
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
                        child: _isAuthenticating
                            ? CircularProgressIndicator()
                            : Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? AppColors.darkAccentColor
                                      : AppColors.accentColor,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: isDarkMode
                                  ? AppColors.darkAccentColor
                                  : AppColors.accentColor,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const LogInPage(initialPage: 1)),
                              );
                            },
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: isDarkMode
                                    ? AppColors.darkAccentColor
                                    : AppColors.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
