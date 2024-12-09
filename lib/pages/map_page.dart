import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_journal/firestore_service.dart';

class MapPage extends StatefulWidget {
  final void Function(Color) onColorUpdate;
  final String taskId;


  const MapPage({Key? key, required this.onColorUpdate, required this.taskId}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194);
  LatLng? _destination;
  Position? _currentPosition;

  final TextEditingController _destinationController = TextEditingController();
  final String _apiKey = 'AIzaSyCKgI8GNYJz7JOt6m7XG6xg2ScwDO5TJYM'; //For the geolocator to work
  final FirestoreService _fsService = FirestoreService();
  String? _storeName;



  @override
  void initState() {
    super.initState();
    _determineCurrentLocation();
  }
  Future<void> _determineCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('Location permission denied. Using default location.');
        return;
      }

      // Request permission if not already granted
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print('Location permissions are denied. Using default location.');
          return;
        }
      }

      // Get current position if permissions are granted
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } catch (e) {
      print('Error fetching location: $e');
    } finally {
      // Load map
      setState(() {});
    }
  }

  Future<void> _goToDestination() async {
    String destination = _destinationController.text;
    if (destination.isNotEmpty) {
      final places = GoogleMapsPlaces(apiKey: _apiKey);
      final response = await places.searchByText(destination);

      if (response.isOkay && response.results.isNotEmpty) {
        final result = response.results.first;

        setState(() {
          _destination = LatLng(
            result.geometry!.location.lat,
            result.geometry!.location.lng,
          );
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_destination!, 14),
        );

        print("Destination found.");
      }
    }
  }


  void _handleMapTap(LatLng tappedPoint) async {
    try {
      // Reverse geocode the tapped location
      List<Placemark> placemarks = await placemarkFromCoordinates(
        tappedPoint.latitude,
        tappedPoint.longitude,
      );

      String address = "Unknown location";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      setState(() {
        // Set tapped location as destination
        _destination = tappedPoint;
      });

      _mapController?.animateCamera(
        // Move camera to tapped location
        CameraUpdate.newLatLngZoom(tappedPoint, 14),
      );

      // Show bottom sheet with address
      _showLocationBottomSheet(address);
    } catch (e) {
      print("Failed to get address: $e");
    }
  }

  void _showLocationBottomSheet(String address) {
    showModalBottomSheet(
      barrierColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set Destination",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                address,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: ()  {
                      _fsService.updateTaskLocation(widget.taskId, address);
                      print('Map: Location / address added to Firebase');
                      Navigator.pop(context, true); // Back to detailedToDo page

                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Destination'),
       // backgroundColor: widget.onColorUpdate,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Custom back button icon
          onPressed: () {
            // Add custom functionality here
            print('Back button pressed');

            // Navigate back to the previous screen (To Do  page)
            Navigator.pop(context, true);
          },
        ),
      ),

      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _handleMapTap, // Call the function when tapping on the map
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _initialPosition,
              zoom: 14,
            ),
            myLocationEnabled: true, // Ensures the location blue dot is displayed
            myLocationButtonEnabled: true, // Enables the default location button
            markers: {
              if (_destination != null)
                Marker(
                  markerId: const MarkerId('destination'),
                  position: _destination!,
                  infoWindow: const InfoWindow(title: 'Destination'),
                ),
            },
          ),
          Positioned(
            top: 7,
            left: 10,
            right: 10,
            child: Row(
              children: [
                SizedBox(
                  width: 290,
                  child: TextField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter destination',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5,),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.purple),
                    iconSize: 28,
                    onPressed: _goToDestination,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}
