import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart'; 

class RegisterScreen extends StatefulWidget {
  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  bool isLoading = false;
  bool obscureText = true;
  bool isLocalGuide = false;

  String? userNameError;
  String? emailError;
  String? passwordError;
  String? countryError;
  String? cityError;
  String? displayNameError;
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
    displayNameController.dispose();
    super.dispose();
  }

  void resetErrors() {
    setState(() {
      userNameError = null;
      emailError = null;
      passwordError = null;
      countryError = null;
      cityError = null;
      displayNameError = null;
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

    if (displayNameController.text.trim().isEmpty) {
      setState(() {
        displayNameError = 'Please enter a display name.';
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
      // Initialize variables to track errors
      bool emailExists = false;
      bool usernameExists = false;

      // Check if email already exists
      emailExists = await _authService.checkEmailExists(emailController.text.trim());

      // Check if username already exists
      usernameExists = await _authService.checkUsernameExists(userNameController.text.trim());

      // If both exist, update the respective error messages
      if (emailExists) {
        setState(() {
          emailError = 'Email already exists.';
        });
      }

      if (usernameExists) {
        setState(() {
          userNameError = 'Username already exists.';
        });
      }

      // If either exists, return early to prevent registration
      if (emailExists || usernameExists) {
        return;
      }

      // Proceed with registration if no errors
      User? user = await _authService.registerWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        userName: userNameController.text.trim(),
        displayName: displayNameController.text.trim(),
        isLocalGuide: isLocalGuide,
        city: selectedCity!,
      );

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text('A verification link has been sent to your email. Please verify your email before logging in.'),
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
        if (e.code == 'email-already-in-use') {
          emailError = 'Email already exists.'; // This might already be handled above, ensure no duplication
        } else {
          emailError = e.message;
        }
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
    bool showLocalGuideCheckbox = selectedCity == 'Riyadh';

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Prevent overflow on smaller screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display Name Field
              TextField(
                controller: displayNameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: displayNameError, // Adjusted here
                ),
              ),
              SizedBox(height: 10),
              // Username Field
              TextField(
                controller: userNameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  errorText: userNameError, // Adjusted here
                ),
              ),
              if (userNameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    userNameError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 10),

              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: emailError, // Adjusted here
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    emailError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 10),
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: passwordError, // Adjusted here
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
                isExpanded: true,
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
                isExpanded: true,
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
              // Local Guide Checkbox (only shows for Riyadh)
              if (showLocalGuideCheckbox)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isLocalGuide,
                      onChanged: (bool? value) {
                        setState(() {
                          isLocalGuide = value!;
                        });
                      },
                    ),
                    const Text('I agree to be a local guide'),
                  ],
                ),
              SizedBox(height: 20),
              // Register Button
              ElevatedButton(
                onPressed: isLoading ? null : handleRegister,
                child: isLoading
                    ? CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}