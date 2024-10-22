import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController passwordController = TextEditingController();
  List<String> selectedInterests = [];
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

  final List<String> interestsOptions = [
    'Technology',
    'Sports',
    'Music',
    'Travel',
    'Food',
    'Art'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

          setState(() {
            selectedCountry = data?['country'];
            selectedCity = data?['city'];
            agreeToLocalGuide =
                data != null && data.containsKey('agreeToLocalGuide')
                    ? data['agreeToLocalGuide']
                    : false;
            selectedInterests = List<String>.from(data?['interests'] ?? []);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load user data: $e'),
      ));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'country': selectedCountry,
        'city': selectedCity,
        'agreeToLocalGuide': agreeToLocalGuide,
        'interests': selectedInterests,
      });

      if (passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(passwordController.text.trim());
      }
    }

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Profile updated successfully! 🎉'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: passwordController,
                      decoration:
                          const InputDecoration(labelText: 'New Password'),
                      obscureText: true,
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
                    const SizedBox(height: 20),
                    if (selectedCountry == 'Saudi Arabia' &&
                        selectedCity == 'Riyadh')
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
                    const Text('Select Interests'),
                    Wrap(
                      children: interestsOptions.map((interest) {
                        return CheckboxListTile(
                          title: Text(interest),
                          value: selectedInterests.contains(interest),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedInterests.add(interest);
                              } else {
                                selectedInterests.remove(interest);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
