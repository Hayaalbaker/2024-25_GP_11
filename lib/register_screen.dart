import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'interests_screen.dart';

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

  bool isLoading = false; // Tracks if registration is in progress
  bool obscureText = true; // Controls password visibility
  bool isLocalGuide = false; // Tracks if the user is a local guide

  String? userNameError;
  String? emailError;
  String? passwordError;
  String? countryError;
  String? cityError;
  String? displayNameError;
  String? selectedCountry;
  String? selectedCity;

  // List of available countries
  List<String> countries = [
    'Saudi Arabia',
    'Egypt',
    'United Arab Emirates',
    'Kuwait',
  ];

  // Map of cities by country
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
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool emailExists = false;
      bool usernameExists = false;

      emailExists =
          await _authService.checkEmailExists(emailController.text.trim());

      usernameExists = await _authService
          .checkUsernameExists(userNameController.text.trim());

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

      if (emailExists || usernameExists) {
        return;
      }

      User? user = await _authService.registerWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        userName: userNameController.text.trim(),
        displayName: displayNameController.text.trim(),
        isLocalGuide: isLocalGuide,
        city: selectedCity!,
        country: selectedCountry!,
      );

      if (user != null) {
        await user.sendEmailVerification();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InterestsScreen(
              email: emailController.text.trim(),
              userName: userNameController.text.trim(),
              country: selectedCountry!,
              city: selectedCity!,
              isLocalGuide: isLocalGuide,
            ),
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
          emailError = 'Email already exists.';
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
      body: Stack(
        children: [
          // Background image with transparency
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/Riyadh.webp'), // Background image
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      errorText: displayNameError,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: userNameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      errorText: userNameError,
                    ),
                  ),
                  if (userNameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        userNameError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (emailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        emailError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: passwordError,
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
                  const SizedBox(height: 10),
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
                        selectedCity = null;
                        countryError = null;
                        isLocalGuide = false;
                      });
                    },
                  ),
                  if (countryError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        countryError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCity,
                    hint: const Text('Select City'),
                    isExpanded: true,
                    items: selectedCountry == null
                        ? []
                        : cities[selectedCountry!]!.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCity = newValue;
                        cityError = null;
                      });
                    },
                  ),
                  if (cityError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        cityError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (showLocalGuideCheckbox)
                    Row(
                      children: [
                        Checkbox(
                          value: isLocalGuide,
                          onChanged: (bool? value) {
                            setState(() {
                              isLocalGuide = value ?? false;
                            });
                          },
                        ),
                        const Text('I agree to be a local guide'),
                      ],
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isLoading ? null : handleRegister,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
