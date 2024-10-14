import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'home_page.dart'; // Ensure the correct filename is used

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  bool isLoading = false;
  bool obscureText = true; // For show/hide password functionality
  String? userNameError; // Error message for username
  String? emailError; // Error message for email
  String? passwordError; // Error message for password
  String? countryError; // Error message for country
  String? cityError; // Error message for city
  String? selectedCountry; // For country dropdown
  String? selectedCity; // For city dropdown

  // Sample data for dropdowns
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: userNameController,
              decoration: InputDecoration(
                labelText: 'Username',
                errorText: userNameError, // Show error for username
              ),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: emailError, // Show error for email
              ),
              keyboardType: TextInputType.emailAddress,
            ),
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
            DropdownButton<String>(
              value: selectedCountry,
              hint: const Text('Select Country'),
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
                });
              },
            ),
            if (countryError != null) // Show error for country
              Text(
                countryError!,
                style: TextStyle(color: Colors.red),
              ),
            DropdownButton<String>(
              value: selectedCity,
              hint: const Text('Select City'),
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
                });
              },
            ),
            if (cityError != null) // Show error for city
              Text(
                cityError!,
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      // Reset all error messages
                      userNameError = null;
                      emailError = null;
                      passwordError = null;
                      countryError = null;
                      cityError = null;

                      // Validate username
                      if (userNameController.text.isEmpty) {
                        userNameError = 'Please enter a username.';
                      }

                      // Validate email
                      if (emailController.text.isEmpty ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(emailController.text)) {
                        emailError = 'Please enter a valid email.';
                      }

                      // Validate password
                      if (passwordController.text.length < 6) {
                        passwordError =
                            'Password must be at least 6 characters long.';
                      }

                      // Validate country and city
                      if (selectedCountry == null) {
                        countryError = 'Please select a country.';
                      }

                      if (selectedCity == null) {
                        cityError = 'Please select a city.';
                      }

                      // Check if there are any errors
                      if (userNameError != null ||
                          emailError != null ||
                          passwordError != null ||
                          countryError != null ||
                          cityError != null) {
                        setState(() {}); // Trigger UI update
                        return; // Exit if there are errors
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        User? user = await _authService.registerWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          userNameController.text.trim(),
                          selectedCity == 'Local Guide', // Example condition
                        );

                        if (mounted) {
                          if (user != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomePage()),
                            );
                          } else {
                            setState(() {
                              emailError = 'Registration failed. Please try again.'; // You can choose to show this under email
                            });
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            emailError = e.toString(); // Update error message under email
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                    child: const Text('Register'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Go back to sign-in screen
              },
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}