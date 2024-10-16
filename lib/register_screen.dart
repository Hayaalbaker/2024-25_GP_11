// register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; // Removed 'welcome_screen.dart' import since it's unused

class RegisterScreen extends StatefulWidget {
  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  bool isLoading = false;
  bool obscureText = true;
  bool isLocalGuide = false; // State variable for Checkbox

  String? userNameError;
  String? emailError;
  String? passwordError;
  String? countryError;
  String? cityError;
  String? selectedCountry;
  String? selectedCity;

  List<String> countries = [
    'Saudi Arabia',
    'Egypt',
    'United Arab Emirates',
    'Kuwait',
  ];

  Map<String, List<String>> cities = {
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Salmiya'],
  };

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  void resetErrors() {
    setState(() {
      userNameError = null;
      emailError = null;
      passwordError = null;
      countryError = null;
      cityError = null;
    });
  }

  bool validateInputs() {
    bool hasError = false;
    resetErrors();

    if (userNameController.text.trim().isEmpty) {
      setState(() {
        userNameError = 'Please enter a username.';
      });
      hasError = true;
    }

    if (emailController.text.trim().isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      setState(() {
        emailError = 'Please enter a valid email.';
      });
      hasError = true;
    }

    if (passwordController.text.trim().length < 6) {
      setState(() {
        passwordError = 'Password must be at least 6 characters long.';
      });
      hasError = true;
    }

    if (selectedCountry == null) {
      setState(() {
        countryError = 'Please select a country.';
      });
      hasError = true;
    }

    if (selectedCity == null) {
      setState(() {
        cityError = 'Please select a city.';
      });
      hasError = true;
    }

    return hasError;
  }

  Future<void> handleRegister() async {
    if (validateInputs()) {
      return; // Exit if there are validation errors
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Pass isLocalGuide as a bool, not a String
      User? user = await _authService.registerWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text.trim(),
        userNameController.text.trim(),
        isLocalGuide as String, // Correct type: bool
        selectedCity! as bool,  // Ensure selectedCity is not null
      );

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text(
                'A verification link has been sent to your email. Please verify your email before logging in.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          emailError = 'Registration failed. Please try again.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        emailError = e.message;
      });
    } catch (e) {
      setState(() {
        emailError = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the Checkbox should be displayed
    bool showLocalGuideCheckbox = selectedCity == 'Riyadh';

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Prevent overflow on smaller screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Username Field
              TextField(
                controller: userNameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: userNameError, // Show error for username
                ),
              ),
              SizedBox(height: 10),
              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError, // Show error for email
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: passwordError, // Show error for password
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Country Dropdown
              DropdownButton<String>(
                value: selectedCountry,
                hint: const Text('Select Country'),
                isExpanded: true, // Make dropdown full width
                items: countries.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    selectedCity = null; // Reset city when country changes
                    countryError = null; // Reset country error
                    isLocalGuide = false; // Reset Checkbox when country changes
                  });
                },
              ),
              if (countryError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    countryError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 10),
              // City Dropdown
              DropdownButton<String>(
                value: selectedCity,
                hint: const Text('Select City'),
                isExpanded: true, // Make dropdown full width
                items: selectedCountry == null
                    ? []
                    : cities[selectedCountry]!.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCity = newValue;
                    cityError = null; // Reset city error
                    if (newValue != 'Riyadh') {
                      isLocalGuide = false; // Reset Checkbox if not Riyadh
                    }
                  });
                },
              ),
              if (cityError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    cityError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 10),
              // Checkbox for Local Guide (only visible if city is Riyadh)
              if (showLocalGuideCheckbox)
                CheckboxListTile(
                  title: const Text('I agree to be a Local Guide'),
                  value: isLocalGuide,
                  onChanged: (bool? value) {
                    setState(() {
                      isLocalGuide = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              SizedBox(height: 20),
              // Register Button
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: handleRegister,
                      child: const Text('Register'),
                    ),
              // Sign-In Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to sign-in screen
                },
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}