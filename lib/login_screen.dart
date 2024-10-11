import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'interests_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                User? user = await _authService.signInWithEmailAndPassword(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
                if (mounted) {
                  if (user != null) {
                    print('Signed in: ${user.email}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Sign in failed. Please check your credentials.')),
                    );
                  }
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  String? selectedCountry;
  String? selectedCity;
  bool agreeToLocalGuide = false;

  final Map<String, List<String>> countryCityMap = {
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Salmiya'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: userNameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                hint: const Text('Select Country'),
                value: selectedCountry,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    selectedCity = null;
                    agreeToLocalGuide = false;
                  });
                },
                items: countryCityMap.keys
                    .map<DropdownMenuItem<String>>((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              DropdownButton<String>(
                hint: const Text('Select City'),
                value: selectedCity,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCity = newValue;
                    if (newValue != 'Riyadh') {
                      agreeToLocalGuide = false;
                    }
                  });
                },
                items: selectedCountry != null
                    ? countryCityMap[selectedCountry]!
                        .map<DropdownMenuItem<String>>((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList()
                    : [],
              ),
              if (selectedCity == 'Riyadh')
                Row(
                  children: [
                    Checkbox(
                      value: agreeToLocalGuide,
                      onChanged: (bool? value) {
                        setState(() {
                          agreeToLocalGuide = value ?? false;
                        });
                      },
                    ),
                    const Text('I agree to become a local guide'),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  User? user = await _authService.registerWithEmailAndPassword(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                  if (mounted) {
                    if (user != null) {
                      print('Registered successfully');
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => InterestsScreen()),
                      );
                    } else {
                      print('Registration failed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Registration failed. Please try again.')),
                      );
                    }
                  }
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
