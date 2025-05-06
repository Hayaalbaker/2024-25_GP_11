import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsPage extends StatelessWidget {
  final Map<String, dynamic> placeData;

  const PlaceDetailsPage({Key? key, required this.placeData}) : super(key: key);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value?.isNotEmpty == true ? value! : 'N/A'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? location = placeData['location'];

    return Scaffold(
      appBar: AppBar(
        title: Text(placeData['place_name'] ?? 'Place Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (placeData['imageUrl'] != null &&
                  placeData['imageUrl'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    placeData['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Failed to load image'),
                  ),
                ),
              const SizedBox(height: 16),

              buildDetailRow('Name', placeData['place_name']),
              buildDetailRow('Description', placeData['description']),

              if (location != null && location.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Location: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _launchURL(location),
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                buildDetailRow('Location', 'N/A'),

              buildDetailRow('Neighborhood', placeData['Neighborhood']),
              buildDetailRow('Street', placeData['Street']),
              buildDetailRow('Category', placeData['category']),
              buildDetailRow('Subcategory', placeData['subcategory']),
            ],
          ),
        ),
      ),
    );
  }
}