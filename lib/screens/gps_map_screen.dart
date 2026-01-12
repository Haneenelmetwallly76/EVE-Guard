import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class GPSMapScreen extends StatefulWidget {
  const GPSMapScreen({super.key});

  @override
  State<GPSMapScreen> createState() => _GPSMapScreenState();
}

class _GPSMapScreenState extends State<GPSMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String _locationStatus = 'Initializing...';
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permission denied forever';
          _isLoading = false;
        });
        await Geolocator.openLocationSettings();
        return;
      }

      setState(() {
        _hasLocationPermission = true;
      });

      // Get current location
      await _getCurrentLocation();

      // Listen for location updates
      _listenToLocationUpdates();
    } catch (e) {
      setState(() {
        _locationStatus = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isLoading = false;
        _updateMarker();
      });

      // Animate camera to current location if map is ready
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _listenToLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _locationStatus = 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _updateMarker();
        });

        // Update camera position if map is ready
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 15,
              ),
            ),
          );
        }
      }
    });
  }

  void _updateMarker() {
    if (_currentPosition != null) {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current GPS Position',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      };
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map View
          if (_currentPosition != null)
            GoogleMap(
              onMapCreated: (controller) {
                if (mounted) {
                  setState(() {
                    _mapController = controller;
                  });
                }
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15,
              ),
              markers: _markers,
              zoomControlsEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // We'll create our own
            )
          else
            Container(
              color: AppTheme.slate50,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      )
                    else
                      const Icon(
                        Icons.location_off_outlined,
                        size: 80,
                        color: AppTheme.slate300,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _locationStatus,
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          // Top Info Card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppTheme.emerald600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GPS Location',
                                  style: AppTheme.headingMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _locationStatus,
                                  style: AppTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Action Buttons
          if (_hasLocationPermission)
            Positioned(
              bottom: 24,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: _centerOnCurrentLocation,
                    backgroundColor: AppTheme.blue600,
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: AppTheme.emerald600,
                    child: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
