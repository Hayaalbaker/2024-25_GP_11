import 'package:flutter/material.dart';
import 'interests_screen.dart'; // Update import statement

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedCountry;
  String? selectedCity;
  String? _errorMessage;
  bool isLoading = false;

  // Dummy countries and cities for demonstration
  final List<String> countries = ['USA', 'Canada', 'Mexico'];
  final Map<String, List<String>> cities = {
    'USA': ['New York', 'Los Angeles', 'Chicago'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal'],
    'Mexico': ['Mexico City', 'Cancun', 'Guadalajara'],
  };

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
              ),
              DropdownButton<String>(
                hint: const Text('Select Country'),
                value: selectedCountry,
                onChanged: (newValue) {
                  setState(() {
                    selectedCountry = newValue;
                    selectedCity = null; // Reset city when country changes
                  });
                },
                items: countries
                    .map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        ))
                    .toList(),
              ),
              if (selectedCountry != null) ...[
                DropdownButton<String>(
                  hint: const Text('Select City'),
                  value: selectedCity,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCity = newValue;
                    });
                  },
                  items: cities[selectedCountry]!
                      .map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          ))
                      .toList(),
                ),
              ],
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        // Validate country and city selection
                        if (selectedCountry == null || selectedCity == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Please select a country and a city.'),
                          ));
                          return;
                        }

                        // Validate email
                        if (emailController.text.isEmpty ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
                          setState(() {
                            _errorMessage = 'Please enter a valid email.';
                          });
                          return;
                        }

                        // Validate password
                        if (passwordController.text.length < 6) {
                          setState(() {
                            _errorMessage = 'Password must be at least 6 characters long.';
                          });
                          return;
                        }

                        setState(() {
                          isLoading = true;
                          _errorMessage = null; // Reset error message
                        });

                        try {
                          // Call the registration method
                          // This should be replaced with your actual registration logic
                          // Simulating successful registration with a delay
                          await Future.delayed(Duration(seconds: 2));

                          // Navigate to InterestsScreen after successful registration
                          final selectedInterests = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InterestsScreen(
                                email: emailController.text,
                                userName: '', // Provide the username if needed
                                country: selectedCountry!,
                                city: selectedCity!,
                                isLocalGuide: false, // Update as necessary
                              ),
                            ),
                          );

                          if (selectedInterests != null) {
                            // Save selected interests to user database
                            // Implement your database saving logic here
                          }

                          Navigator.pop(context); // Go back to SignInScreen
                        } catch (e) {
                          setState(() {
                            _errorMessage = e.toString(); // Update error message
                          });
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
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