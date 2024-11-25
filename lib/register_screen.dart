import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'interests_screen.dart';
import 'signin_screen.dart'; 

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

bool hasUppercase = false;
bool hasLowercase = false;
bool hasDigit = false;
bool hasSpecialChar = false;
bool hasMinLength = false;

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

  @override
void initState() {
  super.initState();

  passwordController.addListener(() {
    final password = passwordController.text;

    setState(() {
      hasUppercase = RegExp(r'(?=.*[A-Z])').hasMatch(password);
      hasLowercase = RegExp(r'(?=.*[a-z])').hasMatch(password);
      hasDigit = RegExp(r'(?=.*\d)').hasMatch(password);
      hasSpecialChar = RegExp(r'(?=.*[@$!%*?&])').hasMatch(password);
      hasMinLength = password.length >= 8;
    });
  });
}
Widget passwordRequirement(String text, bool isMet, {double fontSize = 14}) {
  return Row(
    children: [
      Icon(
        isMet ? Icons.check : Icons.close,
        color: isMet ? Colors.green : Colors.black,
      ),
      const SizedBox(width: 5),
      Text(
        text,
        style: TextStyle(color: isMet ? Colors.green : Colors.black),
      ),
    ],
  );
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

  String password = passwordController.text.trim();
  if (password.length < 8 ||
      !RegExp(r'(?=.*[A-Z])').hasMatch(password) ||  
      !RegExp(r'(?=.*[a-z])').hasMatch(password) || 
      !RegExp(r'(?=.*\d)').hasMatch(password) ||     
      !RegExp(r'(?=.*[@$!%*?&])').hasMatch(password) 
  ) {
    setState(() {
      passwordError = 'Password must be at least 8 characters long, include an uppercase letter, a lowercase letter, a number, and a special character.';
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
        email: emailController.text.trim().toLowerCase(),
        password: passwordController.text.trim(),
        userName: userNameController.text.trim().toLowerCase(),
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
              email: emailController.text.trim().toLowerCase(),
              userName: userNameController.text.trim().toLowerCase(),
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
    appBar: null, 
    body: Stack(
      children: [
        Opacity(
          opacity: 0.1,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/Riyadh.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 90), 
                const Text(
                  "Let's get started",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Please register to sign in",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 20), 
                TextField(
                  controller: displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Name*',
                    errorText: displayNameError,
                    suffixIcon: Tooltip(
                      message: 'This will be your display name, visible to others on the platform. You can use a nickname or any name you’d like',
                      child: Icon(Icons.info_outline),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: userNameController,
                  decoration: InputDecoration(
                    labelText: 'Username*',
                    errorText: userNameError,
                    suffixIcon: Tooltip(
                      message: 'Choose a unique username.',
                      child: Icon(Icons.info_outline),
                    )),
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
                    labelText: 'Email*',
                    errorText: emailError,
                    suffixIcon: Tooltip(
                      message: 'Enter a valid email address.',
                      child: Icon(Icons.info_outline),
                    )),
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
                    labelText: 'Password*',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    passwordRequirement('At least 8 characters', hasMinLength, fontSize: 12),
                    passwordRequirement('One uppercase letter', hasUppercase, fontSize: 12),
                    passwordRequirement('One lowercase letter', hasLowercase, fontSize: 12),
                    passwordRequirement('One digit', hasDigit, fontSize: 12),
                    passwordRequirement('One special character', hasSpecialChar, fontSize: 12),
                  ],
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
                      Tooltip(
                        message:
                            'By agreeing to be a local guide, you’ll be recommended to other users for messaging and assistance. You may be contacted to provide guidance or help within your selected city ',
                        child: Icon(Icons.info_outline),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250, 
                    height: 50, 
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleRegister,
                      child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register', style: TextStyle(fontSize: 18)), 
                      ),
                    ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  },
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          ),
     ) ],
      ),
    );
  }
}