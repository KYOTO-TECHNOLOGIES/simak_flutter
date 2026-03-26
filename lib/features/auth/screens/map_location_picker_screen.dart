import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  LatLng? _selectedLocation;
  String? _address;
  bool _isFetchingAddress = false;
  GoogleMapController? _mapController;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(25.2048, 55.2708), // Dubai
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, 'map_error_location'))),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
        _reverseGeocode(latLng);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return;
    setState(() {
      _isFetchingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        
        if (mounted) {
          setState(() {
            _address = [p.thoroughfare, p.subLocality, p.locality, p.administrativeArea]
                .where((s) => s != null && s.isNotEmpty)
                .join(', ');
          });
        }
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingAddress = false;
        });
      }
    }
  }

  void _onConfirm() async {
    if (_selectedLocation == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final addressParts = _address?.split(', ') ?? [];
        
        // Smarter, more aggressive mapping for auto-fill
        String building = p.name ?? '';
        String street = p.thoroughfare ?? '';
        
        // If street is empty but we have address parts, try to extract it
        if (street.isEmpty && addressParts.isNotEmpty) {
           street = addressParts[0];
        }

        String area = p.subLocality ?? p.locality ?? '';
        if (area.isEmpty && addressParts.length > 1) {
           area = addressParts[1];
        }

        String city = p.subAdministrativeArea ?? p.locality ?? '';
        if (city.isEmpty && addressParts.length > 2) {
           city = addressParts[2];
        }

        String emirate = p.administrativeArea ?? 'Dubai';

        final result = {
          'building': building,
          'street': street,
          'area': area,
          'city': city,
          'emirate': emirate,
          'fullAddress': _address ?? '',
        };
        if (mounted) Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context, {'fullAddress': _address ?? ''});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          tr(context, 'map_select_location'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.08), height: 1),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              setState(() {
                _selectedLocation = position.target;
              });
            },
            onCameraIdle: () {
              if (_selectedLocation != null) {
                _reverseGeocode(_selectedLocation!);
              }
            },
          ),
          
          // Fixed Center Marker with Hint
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35), // Adjust for marker base
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Drag map to move pin',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 44,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (_address != null || _isFetchingAddress)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          tr(context, 'map_select_location').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            color: AppColors.primary.withOpacity(0.5),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isFetchingAddress
                        ? const Center(child: Padding(
                           padding: EdgeInsets.all(8.0),
                           child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                         ))
                        : Text(
                            _address ?? '',
                            style: const TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                  ],
                ),
              ),
            ),
            
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _selectedLocation == null || _isFetchingAddress 
                  ? [] 
                  : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
              ),
              child: ElevatedButton(
                onPressed: _selectedLocation == null || _isFetchingAddress
                    ? null
                    : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  tr(context, 'map_confirm_location').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
