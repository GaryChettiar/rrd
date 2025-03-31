import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodBankMapScreen extends StatefulWidget {
  final Position position;
  final List<Map<String, dynamic>> bloodBanks;

  BloodBankMapScreen({
    required this.position, 
    this.bloodBanks = const [], // Default to empty list if not provided
  });

  @override
  _BloodBankMapScreenState createState() => _BloodBankMapScreenState();
}

class _BloodBankMapScreenState extends State<BloodBankMapScreen> {
  late final MapController _mapController;
  double _currentZoom = 14.0;
  late List<Map<String, dynamic>> bloodBanks;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    bloodBanks = widget.bloodBanks; // Initialize with the passed-in data
    
    print("🔄 Initializing map with ${bloodBanks.length} blood banks");
    for (var bank in bloodBanks) {
      print("✅ Blood Bank: ${bank["name"]}, Lat: ${bank["lat"]}, Lon: ${bank["lon"]}");
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

  // Open directions to a blood bank
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
    print("📌 Rebuilding UI with ${bloodBanks.length} blood banks");

    return Scaffold(
      appBar: AppBar(title: Text("Nearby Blood Banks")),
      body: Column(
        children: [
          // 🔹 Map with fixed height
          SizedBox(
            height: 300, // Adjust map height as needed
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
                        // User's location marker
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(widget.position.latitude, widget.position.longitude),
                          child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                        ),
                        // Blood Bank Markers
                        ...bloodBanks.map((bank) => Marker(
                              width: 40.0,
                              height: 40.0,
                              point: LatLng(bank["lat"], bank["lon"]),
                              child: Icon(Icons.bloodtype, color: Colors.red, size: 40),
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
                        heroTag: "zoomInBloodBank",
                      ),
                      SizedBox(height: 10),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _zoomOut,
                        child: Icon(Icons.remove),
                        heroTag: "zoomOutBloodBank",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Debug UI Showing Total Blood Banks
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Total Blood Banks: ${bloodBanks.length}", 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          // 🔹 List of Blood Banks Below
          Expanded(
            child: bloodBanks.isNotEmpty
                ? ListView.builder(
                    itemCount: bloodBanks.length,
                    itemBuilder: (context, index) {
                      final bank = bloodBanks[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: Icon(Icons.bloodtype, color: Colors.red),
                          title: Text(bank["name"] ?? "Unknown Blood Bank"),
                          subtitle: Text(bank["display_name"] ?? "Location not available"),
                          trailing: ElevatedButton.icon(
                            icon: Icon(Icons.directions),
                            label: Text("Directions"),
                            onPressed: () => _openDirections(
                              bank["lat"],
                              bank["lon"],
                              bank["name"] ?? "Blood Bank",
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
                : Center(child: Text("No blood banks found nearby.")),
          ),
        ],
      ),
    );
  }
}