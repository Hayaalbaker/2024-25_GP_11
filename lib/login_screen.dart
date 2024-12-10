import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localize/Home_Page.dart';
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
  bool isLoading = false;

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
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      User? user = await _authService.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      setState(() {
                        isLoading = false;
                      });

                      if (mounted) {
                        if (user != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Log in failed. Please check your credentials.'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
                            ),
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
  bool isLoading = false;

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
              if (selectedCountry == 'Saudi Arabia' && selectedCity == 'Riyadh')
                CheckboxListTile(
                  title: const Text('I agree to become a local guide'),
                  value: agreeToLocalGuide,
                  onChanged: (bool? value) {
                    setState(() {
                      agreeToLocalGuide = value ?? false;
                    });
                  },
                ),
              const SizedBox(height: 20),
              if (isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (selectedCountry == null || selectedCity == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Please select a country and a city.'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
                      ));
                      return;
                    }

                    setState(() {
                      isLoading = true;
                    });

                    try {
                    User? user = await _authService.registerWithEmailAndPassword(
  email: emailController.text.trim(),
  password: passwordController.text.trim(),
  userName: userNameController.text.trim(),
  displayName: userNameController.text.trim(),
  isLocalGuide: agreeToLocalGuide,
  city: selectedCity!,
  country: selectedCountry!,
);


                      setState(() {
                        isLoading = false;
                      });

                      if (user != null) {
                        String userId = user.uid;
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .set({
                          'email': emailController.text.trim(),
                          'userName': userNameController.text.trim(),
                          'country': selectedCountry,
                          'city': selectedCity,
                          'agreeToLocalGuide': agreeToLocalGuide,
                        });

                        print('Registered successfully');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return InterestsScreen(
                                email: emailController.text.trim(),
                                userName: userNameController.text.trim(),
                                country: selectedCountry!,
                                city: selectedCity!,
                                isLocalGuide: agreeToLocalGuide,
                              );
                            },
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration failed. Please try again.'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registration failed: $e'),
          behavior: SnackBarBehavior.floating, 
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),),
                      );
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


