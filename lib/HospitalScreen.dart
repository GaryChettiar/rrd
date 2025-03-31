import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalMapScreen extends StatefulWidget {
  final Position position;
  final List<Map<String, dynamic>> hospitals;

  HospitalMapScreen({
    required this.position,
    this.hospitals = const [], // Default to empty list if not provided
  });

  @override
  _HospitalMapScreenState createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  late final MapController _mapController;
  double _currentZoom = 14.0;
  late List<Map<String, dynamic>> hospitals;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    hospitals = widget.hospitals; // Initialize with the passed-in data
    
    print("🔄 Initializing map with ${hospitals.length} hospitals");
    for (var hospital in hospitals) {
      print("✅ Hospital: ${hospital["name"]}, Lat: ${hospital["lat"]}, Lon: ${hospital["lon"]}");
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  // Open directions to a hospital
  Future<void> _openDirections(double lat, double lon, String name) async {
    // Use Google Maps URL scheme
    final url = 'https://www.google.com/maps/dir/?api=1&origin=${widget.position.latitude},${widget.position.longitude}&destination=$lat,$lon&travelmode=driving&dir_action=navigate';
    
    // Encode the URL 
    final encodedUrl = Uri.encodeFull(url);
    
    try {
      if (await canLaunch(encodedUrl)) {
        await launch(encodedUrl);
      } else {
        throw 'Could not launch $encodedUrl';
      }
    } catch (e) {
      print("Error launching maps: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open directions. Maps app may not be installed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("📌 Rebuilding UI with ${hospitals.length} hospitals");

    return Scaffold(
      appBar: AppBar(title: Text("Nearby Hospitals")),
      body: Column(
        children: [
          // 🔹 Map with Fixed Height
          SizedBox(
            height: 300, // Adjust the height if needed
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: LatLng(widget.position.latitude, widget.position.longitude),
                    zoom: _currentZoom,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        // User's Location Marker
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(widget.position.latitude, widget.position.longitude),
                          child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                        ),
                        // Hospital Markers
                        ...hospitals.map((hospital) => Marker(
                              width: 40.0,
                              height: 40.0,
                              point: LatLng(hospital["lat"], hospital["lon"]),
                              child: Icon(Icons.local_hospital, color: Colors.red, size: 40),
                            )),
                      ],
                    ),
                  ],
                ),
                // 🔹 Zoom Buttons
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        mini: true,
                        onPressed: _zoomIn,
                        child: Icon(Icons.add),
                        heroTag: "zoomIn",
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _zoomOut,
                        child: Icon(Icons.remove),
                        heroTag: "zoomOut",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Debug UI Showing Total Hospitals
         

          // 🔹 List of Hospitals Below
          Expanded(
            child: hospitals.isNotEmpty
                ? ListView.builder(
                    itemCount: hospitals.length,
                    itemBuilder: (context, index) {
                      final hospital = hospitals[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: Icon(Icons.local_hospital, color: Colors.red),
                          title: Text(hospital["name"]),
                          subtitle: Text("Lat: ${hospital["lat"].toStringAsFixed(4)}, Lon: ${hospital["lon"].toStringAsFixed(4)}"),
                          trailing: ElevatedButton.icon(
                            icon: Icon(Icons.directions),
                            label: Text("Directions"),
                            onPressed: () => _openDirections(
                              hospital["lat"],
                              hospital["lon"],
                              hospital["name"],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: Text("No hospitals found nearby.")),
          ),
        ],
      ),
    );
  }
}