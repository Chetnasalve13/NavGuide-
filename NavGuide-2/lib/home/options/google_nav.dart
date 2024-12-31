import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_maps_webservice/directions.dart' hide Polyline;
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_compass/flutter_compass.dart';

class StartNavigationPage extends StatefulWidget {
  const StartNavigationPage({Key? key}) : super(key: key);

  @override
  _StartNavigationPageState createState() => _StartNavigationPageState();
}

class _StartNavigationPageState extends State<StartNavigationPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _destination = '';
  final TextEditingController _searchController = TextEditingController();
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  double? _heading;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToCompass();
  }

  void _listenToCompass() {
    FlutterCompass.events!.listen((CompassEvent compassEvent) {
      setState(() {
        _heading = compassEvent.heading;
      });
    });
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14.0,
        ),
      );
    }

    Geolocator.getPositionStream().listen((Position newPosition) {
      setState(() {
        _currentPosition = newPosition;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
            LatLng(newPosition.latitude, newPosition.longitude)),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14.0,
        ),
      );
    }
  }

  void _confirmDestination() async {
    _speak("You said $_destination. Do you want to start navigation?");
    _getDestinationCoordinates(_destination);
  }

  void _getDestinationCoordinates(String destination) async {
    if (destination.isEmpty) {
      _speak("Please enter a destination.");
      return;
    }

    try {
      final places =
          GoogleMapsPlaces(apiKey: 'AIzaSyDf9HqHeI7kiDPpxF7jnP6OSIvZmP6p8kE');

      // Log the destination search
      print("Searching for: $destination");

      PlacesSearchResponse response = await places.searchByText(destination);

      // Log the raw response for debugging
      print("Places API Response: ${response.toJson()}");

      if (response.results.isNotEmpty) {
        var firstResult = response.results[0];

        // Log the first result details
        print(
            "First result: ${firstResult.name}, ${firstResult.geometry?.location}");

        if (firstResult.geometry != null) {
          LatLng destLocation = LatLng(
            firstResult.geometry!.location.lat,
            firstResult.geometry!.location.lng,
          );
          _plotRouteOnMap(destLocation);
        } else {
          _speak("Could not find valid coordinates for the destination.");
        }
      } else {
        _speak("Destination not found. Please try again.");
      }
    } catch (e) {
      _speak("There was an error finding the destination: $e");
      // Log the error for debugging
      print("Error during API request: $e");
    }
  }

  List<LatLng> decodePolyline(String poly) {
    List<LatLng> polyline = [];
    int index = 0, len = poly.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) == 1 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng((lat / 1E5), (lng / 1E5)));
    }

    return polyline;
  }

  void _plotRouteOnMap(LatLng destination) async {
    if (_currentPosition == null) return;

    final directions = GoogleMapsDirections(apiKey: 'YOUR_GOOGLE_API_KEY');

    DirectionsResponse response = await directions.directionsWithLocation(
      Location(
          lat: _currentPosition!.latitude, lng: _currentPosition!.longitude),
      Location(lat: destination.latitude, lng: destination.longitude),
    );

    if (response.routes.isNotEmpty) {
      final route = response.routes[0];
      List<LatLng> points = route.legs[0].steps
          .expand((step) => decodePolyline(step.polyline.points))
          .toList();

      setState(() {
        _routePoints = points;
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
        );
      });
      _sendNavigationInstructions(response);
    } else {
      _speak("Route not found.");
    }
  }

  void _sendNavigationInstructions(DirectionsResponse response) async {
    for (var leg in response.routes[0].legs) {
      for (var step in leg.steps) {
        _speak(step.htmlInstructions);
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Navigation'),
      ),
      body: Stack(
        children: [
          _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    zoom: 14.0,
                  ),
                  markers: _currentPosition != null
                      ? {
                          Marker(
                            markerId: MarkerId('currentLocation'),
                            position: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            infoWindow: InfoWindow(title: "Your Location"),
                          ),
                        }
                      : {},
                  polylines: _polylines,
                ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter destination',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _destination = _searchController.text;
                    });
                    _confirmDestination();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 10,
            child: _heading == null
                ? CircularProgressIndicator()
                : Text("Heading: ${_heading!.toStringAsFixed(2)}°"),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  if (!_isListening) {
                    // _startListening();
                  }
                },
                child: Icon(Icons.mic, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
