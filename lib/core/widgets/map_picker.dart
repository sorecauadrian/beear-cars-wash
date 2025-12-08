import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

/// Map picker widget for selecting a location
class MapPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const MapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(47.1333, 24.4833); // Bistrita center
  String _addressText = 'Se încarcă adresa...';
  bool _isLoadingAddress = false;
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
        _addressText = widget.initialAddress!;
      } else {
        _getAddressFromCoordinates(_selectedLocation);
      }
    } else {
      _requestLocationPermission();
      // Get address for initial location
      _getAddressFromCoordinates(_selectedLocation);
    }
    _updateMarker();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted && mounted) {
      // Could get current location here if needed
    }
  }

  void _updateMarker() {
    if (!mounted) return;
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation,
        draggable: true,
        onDragEnd: (LatLng newPosition) {
          if (!mounted) return;
          _selectedLocation = newPosition;
          _getAddressFromCoordinates(newPosition);
        },
      );
    });
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingAddress = true;
      _addressText = 'Se încarcă adresa...';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final addressParts = <String>[];
        
        // Build address in Romanian format: Strada X, nr. Y, Oraș, Județ
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
          addressParts.add('nr. ${place.subThoroughfare}');
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        if (!mounted) return;
        
        setState(() {
          if (addressParts.isNotEmpty) {
            _addressText = addressParts.join(', ');
          } else {
            // Fallback: try to get a readable address from name or thoroughfare
            if (place.name != null && place.name!.isNotEmpty) {
              _addressText = place.name!;
            } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
              _addressText = place.thoroughfare!;
            } else {
              _addressText = 'Locație selectată (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
            }
          }
          _isLoadingAddress = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _addressText = 'Locație selectată (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // On error, still show a readable format instead of raw coordinates
      setState(() {
        _addressText = 'Locație selectată (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _isLoadingAddress = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = position;
    });
    _updateMarker();
    _getAddressFromCoordinates(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selectează locația'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _selectedLocation.latitude,
                'lng': _selectedLocation.longitude,
                'address': _addressText,
              });
            },
            child: const Text(
              'Confirmă',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (mounted) {
                _mapController = controller;
              }
            },
            onTap: _onMapTap,
            markers: _marker != null ? {_marker!} : {},
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            compassEnabled: true,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Adresă selectată:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingAddress)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Se încarcă adresa...'),
                        ],
                      )
                    else
                      Text(
                        _addressText,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
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

