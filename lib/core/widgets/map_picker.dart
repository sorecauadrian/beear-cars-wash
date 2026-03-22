import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_spacing.dart';

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
  LatLng _selectedLocation = const LatLng(47.1333, 24.4833);
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
      _getAddressFromCoordinates(_selectedLocation);
    }
    _updateMarker();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted && mounted) {
      // Could get current location here
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
          } else if (place.name != null && place.name!.isNotEmpty) {
            _addressText = place.name!;
          } else if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            _addressText = place.thoroughfare!;
          } else {
            _addressText = _coordsFallback(position);
          }
          _isLoadingAddress = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _addressText = _coordsFallback(position);
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressText = _coordsFallback(position);
        _isLoadingAddress = false;
      });
    }
  }

  String _coordsFallback(LatLng pos) =>
      'Locație selectată (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';

  void _onMapTap(LatLng position) {
    if (!mounted) return;
    setState(() => _selectedLocation = position);
    _updateMarker();
    _getAddressFromCoordinates(position);
  }

  Map<String, dynamic> _buildResult() => {
    'lat': _selectedLocation.latitude,
    'lng': _selectedLocation.longitude,
    'address': _isLoadingAddress ? _coordsFallback(_selectedLocation) : _addressText,
  };

  void _confirm() => Navigator.pop(context, _buildResult());

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirm();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Selectează locația'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirm,
          ),
        ),
        body: Stack(
          children: [
            // Map fills everything
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 14,
                ),
                onMapCreated: (GoogleMapController controller) {
                  if (mounted) _mapController = controller;
                },
                onTap: _onMapTap,
                markers: _marker != null ? {_marker!} : {},
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                compassEnabled: true,
                padding: EdgeInsets.only(bottom: 180 + bottomPadding),
              ),
            ),

            // Zoom controls top-right
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Column(
                children: [
                  _mapControlButton(Icons.add, () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  }),
                  const SizedBox(height: 8),
                  _mapControlButton(Icons.remove, () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  }),
                ],
              ),
            ),

            // Bottom panel: address + confirm button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.outline,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Adresă selectată',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (_isLoadingAddress)
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Se încarcă adresa...',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          _addressText,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingAddress ? null : _confirm,
                                icon: const Icon(Icons.check_rounded, size: 20),
                                label: const Text('Confirmă locația'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
