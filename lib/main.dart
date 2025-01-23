import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(AirQualityMapApp());
}

class AirQualityMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Quality Map',
      home: AirQualityMapPage(),
    );
  }
}

class AirQualityMapPage extends StatefulWidget {
  @override
  _AirQualityMapPageState createState() => _AirQualityMapPageState();
}

class _AirQualityMapPageState extends State<AirQualityMapPage> {
  final List<Marker> _markers = [];
  final LatLng _initialCenter = LatLng(11.5564, 104.9282); // Phnom Penh
  final double _initialZoom = 8.0;
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _startLiveTracking();
    _fetchAirQualityData();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  /// Start live location tracking
  void _startLiveTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    // Start listening for location updates
    _positionStream =
        Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _updateUserLocationMarker();
      });
    });
  }

  /// Update the user's location marker on the map
  void _updateUserLocationMarker() {
    if (_userLocation != null) {
      // Remove the existing user marker, if any
      _markers.removeWhere((marker) => marker.point == _userLocation);

      // Add the updated user marker
      _markers.add(
        Marker(
          point: _userLocation!,
          width: 50.0,
          height: 50.0,
          // Use 'child' parameter instead of 'builder'
          child: Icon(
            Icons.person_pin_circle,
            color: Colors.blue,
            size: 50.0,
          ),
        ),
      );
    }
  }

  Future<void> _fetchAirQualityData() async {
    final apiKey = '<68ec67f3-fec0-4b7e-b08c-979df54763b4>';
    final locations = [
      {'lat': 11.5564, 'lon': 104.9282, 'city': 'Phnom Penh'},
      {'lat': 10.8231, 'lon': 106.6297, 'city': 'Ho Chi Minh City'},
      {'lat': 13.7563, 'lon': 100.5018, 'city': 'Bangkok'}
    ];

    for (var location in locations) {
      final url = Uri.parse(
          'https://api.airvisual.com/v2/nearest_city?lat=${location['lat']}&lon=${location['lon']}&key=$apiKey');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aqi = data['data']['current']['pollution']['aqius'];

          setState(() {
            _markers.add(
              Marker(
                point: LatLng(
                    location['lat'] as double, location['lon'] as double),
                width: 40.0,
                height: 40.0,
                // Use 'child' parameter instead of 'builder'
                child: _buildMarkerIcon(aqi),
              ),
            );
          });
        }
      } catch (e) {
        print('Error fetching data for ${location['city']}: $e');
      }
    }
  }

  Widget _buildMarkerIcon(int aqi) {
    Color markerColor;

    if (aqi <= 50) {
      markerColor = Colors.green;
    } else if (aqi <= 100) {
      markerColor = Colors.yellow;
    } else if (aqi <= 150) {
      markerColor = Colors.orange;
    } else if (aqi <= 200) {
      markerColor = Colors.red;
    } else {
      markerColor = Colors.purple;
    }

    return Icon(
      Icons.location_on,
      color: markerColor,
      size: 40.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Air Quality Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _userLocation ?? _initialCenter,
          initialZoom: _initialZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userLocation != null) {
            setState(() {
              // Center map on user location
            });
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
