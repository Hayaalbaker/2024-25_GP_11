import 'package:flutter/material.dart';
import 'reset_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';

class ProfileSettingsPage extends StatelessWidget {
  // ignore: unused_field
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: unused_field
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Account Information"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccountInformationPage()),
              );
            },
          ),
          ListTile(
            title: Text("Change your password"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordPage()),
              );
            },
          ),
          ListTile(
            title: Text("Delete your account"),
            onTap: () {
              // Handle delete account logic here
              print("Delete account tapped");
            },
          ),
        ],
      ),
    );
  }
}

class AccountInformationPage extends StatefulWidget {
  @override
  _AccountInformationPageState createState() => _AccountInformationPageState();
}

class _AccountInformationPageState extends State<AccountInformationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  String? _selectedCountry;
  String? _selectedCity;

  bool _hasUnsavedChanges = false;

  Map<String, List<String>> cities = {
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Salmiya'],
  };
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _usernameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _usernameController.text = userDoc['user_name'] ?? '';
        _emailController.text = user.email ?? '';
        _selectedCountry = userDoc['country'];
        _selectedCity = userDoc['city'];
        _hasUnsavedChanges = false; // Reset when data is loaded
      });
    }
  }

  Future<void> _updateUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'user_name': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'country': _selectedCountry,
        'city': _selectedCity,
      });
      setState(() {
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Information updated!')));
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Unsaved Changes'),
            content:
                Text('You have unsaved changes. Do you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Stay
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Discard
                child: Text('Discard'),
              ),
            ],
          );
        },
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  void _signOut() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Account Information"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCountry,
                  hint: Text('Select Country'),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCountry = newValue;
                      _selectedCity = null;
                      _hasUnsavedChanges = true;
                    });
                  },
                  items: [
                    'Saudi Arabia',
                    'Egypt',
                    'United Arab Emirates',
                    'Kuwait'
                  ]
                      .map((country) => DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCity,
                  hint: Text('Select City'),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCity = newValue;
                      _hasUnsavedChanges = true;
                    });
                  },
                  items: _selectedCountry != null
                      ? cities[_selectedCountry]!
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ))
                          .toList()
                      : [],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _updateUserInfo,
                  child: Text('Update Information'),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _signOut,
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController _currentPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();

  Future<void> _changePassword() async {
    User? user = _auth.currentUser;
    try {
      // Re-authenticate the user
      String email = user!.email!;
      AuthCredential credential = EmailAuthProvider.credential(
          email: email, password: _currentPasswordController.text);
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed successfully!')));
      Navigator.pop(context); // Return to Profile Settings
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error changing password: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ResetPasswordScreen()),
                );
              },
              child: const Text('Forgot Password?'),
            ),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Change Password'),
            ),
            SizedBox(height: 20),
            // Password requirements display
            Column(
              children: [
                _passwordRequirement('At least 8 characters',
                    _newPasswordController.text.length >= 8),
                _passwordRequirement('One uppercase letter',
                    _newPasswordController.text.contains(RegExp(r'[A-Z]'))),
                _passwordRequirement('One lowercase letter',
                    _newPasswordController.text.contains(RegExp(r'[a-z]'))),
                _passwordRequirement('One digit',
                    _newPasswordController.text.contains(RegExp(r'[0-9]'))),
                _passwordRequirement(
                    'One special character',
                    _newPasswordController.text
                        .contains(RegExp(r'[!@#\$&*~]'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordRequirement(String text, bool requirementMet) {
    return Row(
      children: [
        Icon(requirementMet ? Icons.check : Icons.clear,
            color: requirementMet ? Colors.green : Colors.red),
        SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}