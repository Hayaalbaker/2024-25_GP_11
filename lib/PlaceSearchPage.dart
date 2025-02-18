import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'places_widget.dart';
import 'add_place.dart';
import "view_Place.dart";

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
        places = querySnapshot.docs
            .map((doc) {
              if (doc.data().containsKey('place_name')) {
                return {
                  'id': doc.id,
                  'name': doc['place_name'] as String,
                };
              } else {
                print('place_name field is missing in document: ${doc.id}');
                return null;
              }
            })
            .where((place) => place != null)
            .map((place) => place as Map<String, String>)
            .toList();
      });

      print('Fetched places: $places');
    } catch (e) {
      print('Error fetching places: $e');
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
                  print('Text is empty');
                  return const Iterable<String>.empty();
                }

                final filteredPlaces = places
                    .map((place) => place['name']!)
                    .where((name) => name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()))
                    .toList();

                print('Filtered places: $filteredPlaces');
                return filteredPlaces;
              },
              onSelected: (String selectedPlace) {
                setState(() {
                  selectedPlaceName = selectedPlace;
                  selectedPlaceId = places.firstWhere(
                      (place) => place['name'] == selectedPlace)['id'];
                  _placeErrorText = null;
                });

                print('Selected place: $selectedPlace');
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
                );
              },
            ),
            if (_placeErrorText != null) linktoaddpage(),
            const SizedBox(height: 20),
            Expanded(
              child: PlacesWidget(
                placeIds: selectedPlaceId != null ? [selectedPlaceId!] : [],
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
            'Go to Add Place Page.',
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
