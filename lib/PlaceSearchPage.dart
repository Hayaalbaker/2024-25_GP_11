import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'places_widget.dart';
import 'add_place.dart';

class PlaceSearchPage extends StatefulWidget {
  @override
  _PlaceSearchPageState createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  List<Map<String, String>> places = [];
  String? selectedPlaceName;
  String? selectedPlaceId;
  String? _placeErrorText;
  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('places').get();
      setState(() {
        places = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['place_name'] as String,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching places: $e');
    }
  }

  void _validatePlaceSelection() {
    if (selectedPlaceName == null ||
        !places.any((place) => place['name'] == selectedPlaceName)) {
      setState(() {
        _placeErrorText = 'Please select a valid place from the list.';
      });
    } else {
      setState(() {
        _placeErrorText = null; // Clear error if valid
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return places.map((place) => place['name']!).where((name) =>
                    name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selectedPlace) {
                setState(() {
                  selectedPlaceName = selectedPlace;
                  selectedPlaceId = places.firstWhere(
                      (place) => place['name'] == selectedPlace)['id'];
                  _placeErrorText = null;
                });
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Search for a place',
                    border: OutlineInputBorder(),
                    hintText: 'Enter a place name',
                    errorText: _placeErrorText,
                  ),
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _placeErrorText = 'Place name cannot be empty.';
                        selectedPlaceName = null;
                        selectedPlaceId = null;
                      } else if (!places
                          .any((place) => place['name'] == value)) {
                        _placeErrorText = 'Place not found. ';
                        selectedPlaceName = null;
                        selectedPlaceId = null;
                      } else {
                        _placeErrorText = null; // Clear error
                        selectedPlaceName = value;
                        selectedPlaceId = places.firstWhere(
                            (place) => place['name'] == value)['id'];
                      }
                    });
                  },
                );
              },
            ),
            if (_placeErrorText != null) linktoaddpage(),
            const SizedBox(height: 20),
            Expanded(
              child: Places_widget(
                placeIds: selectedPlaceId != null ? [selectedPlaceId!] : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget linktoaddpage() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPlacePage(),
              ),
            );
          },
          child: Text(
            'go to Add Place Page.',
            style: TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
