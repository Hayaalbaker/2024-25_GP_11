import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'places_widget.dart';

class PlaceSearchPage extends StatefulWidget {
  @override
  _PlaceSearchPageState createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  List<Map<String, String>> places = [];
  String? selectedPlaceName;
  String? selectedPlaceId;
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
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Clear `selectedPlaceId` if user manually changes the text
                      selectedPlaceName = value;
                      selectedPlaceId = null;
                    });
                  },
                );
              },
            ),
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
}
