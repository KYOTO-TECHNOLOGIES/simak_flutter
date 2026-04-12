import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uae_ecom_project/features/auth/controller/system_controller.dart';
import 'package:uae_ecom_project/core/config/app_colors.dart';
import 'dart:async';

class MapPickerResult {
  final double lat;
  final double lng;
  final String? street;
  final String? area;
  final String? city;
  final String? emirate;
  final String? fullAddress;

  MapPickerResult({
    required this.lat,
    required this.lng,
    this.street,
    this.area,
    this.city,
    this.emirate,
    this.fullAddress,
  });
}

class GoogleMapPicker extends StatefulWidget {
  final Function(MapPickerResult) onSelect;
  final double defaultLat;
  final double defaultLng;

  const GoogleMapPicker({
    super.key,
    required this.onSelect,
    this.defaultLat = 25.2048,
    this.defaultLng = 55.2708,
  });

  @override
  State<GoogleMapPicker> createState() => _GoogleMapPickerState();
}

class _GoogleMapPickerState extends State<GoogleMapPicker> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _address = '';
  bool _isLocating = false;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = LatLng(widget.defaultLat, widget.defaultLng);
    _reverseGeocode(_currentPosition!);
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() => _isReverseGeocoding = true);
    
    // Notify parent that we are updating (useful for showing loading in fields if needed)
    widget.onSelect(MapPickerResult(
      lat: position.latitude,
      lng: position.longitude,
    ));

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        // Construct a better readable address
        final parts = [
          if (place.name != null && place.name != place.street) place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((p) => p != null && p!.isNotEmpty).toList();

        final fullAddress = parts.join(', ');

        setState(() {
          _address = fullAddress;
        });

        widget.onSelect(MapPickerResult(
          lat: position.latitude,
          lng: position.longitude,
          street: place.street ?? place.name,
          area: place.subLocality ?? place.subAdministrativeArea,
          city: place.locality,
          emirate: place.administrativeArea,
          fullAddress: fullAddress,
        ));
      }
    } catch (e) {
      debugPrint('Reverse Geocoding Error: $e');
      // Still send the coordinates back even if geocoding fails
      widget.onSelect(MapPickerResult(
        lat: position.latitude,
        lng: position.longitude,
      ));
      if (mounted) {
        setState(() => _isReverseGeocoding = false);
      }
    }
  }

  Future<void> _handleUseLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      LatLng newPos = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = newPos;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(newPos));
      await _reverseGeocode(newPos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  final _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }

      try {
        final apiKey = context.read<SystemController>().config?.googleMapsApiKey;
        if (apiKey == null) {
          debugPrint('Places Autocomplete: No API Key available');
          return;
        }

        final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$query&key=$apiKey&components=country:ae'; // Limit to UAE
        final response = await context.read<SystemController>().dio.get(url);
        if (!mounted) return;
        if (response.statusCode == 200) {
          setState(() {
            _suggestions = response.data['predictions'] as List<dynamic>;
          });
        }
      } catch (e) {
        debugPrint('Places Autocomplete Error: $e');
      }
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['place_id'];
    final apiKey = context.read<SystemController>().config?.googleMapsApiKey;
    if (apiKey == null) return;

    setState(() {
      _suggestions = [];
      _searchController.text = suggestion['description'];
      _isSearching = true;
    });

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId&key=$apiKey';
      final response = await context.read<SystemController>().dio.get(url);
      if (response.statusCode == 200) {
        final location = response.data['result']['geometry']['location'];
        final newPos = LatLng(location['lat'], location['lng']);
        
        setState(() {
          _currentPosition = newPos;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
        await _reverseGeocode(newPos);
      }
    } catch (e) {
      debugPrint('Place Details Error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _performManualSearch(String query) async {
    if (query.isEmpty) return;
    
    // If we have suggestions, use the first one as it's likely what the user wants
    if (_suggestions.isNotEmpty) {
      _selectSuggestion(_suggestions.first as Map<String, dynamic>);
      return;
    }

    setState(() => _isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newPos = LatLng(loc.latitude, loc.longitude);
        
        setState(() {
          _currentPosition = newPos;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
        await _reverseGeocode(newPos);
      }
    } catch (e) {
      debugPrint('Manual Search Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find location. Please try a more specific address.')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'PIN YOUR LOCATION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Search bar and My Location Button Row
        Row(
          children: [
            // Search Bar
            Expanded(
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) => _performManualSearch(value),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                    hintText: 'Search for your location...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Styled My Location Button
            SizedBox(
              height: 45,
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _handleUseLocation,
                icon: _isLocating 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.navigation, size: 16, color: Colors.white),
                label: const Text(
                  'My Location',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0089BD), // Blue color from screenshot
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        
        // Search Suggestions Overlay (simplified as a list below)
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(s['description'], style: const TextStyle(fontSize: 12)),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
          
        const SizedBox(height: 12),

        // Map Container
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4), // Flat corners matching screenshot
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: (position) {
                  setState(() {
                    _currentPosition = position.target;
                  });
                },
                onCameraIdle: () {
                  if (_currentPosition != null) {
                    _reverseGeocode(_currentPosition!);
                  }
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: _currentPosition!,
                    draggable: true,
                    onDragEnd: (newPos) {
                      setState(() {
                        _currentPosition = newPos;
                      });
                      _reverseGeocode(newPos);
                    },
                  ),
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              ),

              // Classic Center Pin Overlay
              IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_pin, size: 40, color: Colors.red.shade700),
                  ),
                ),
              ),
              
              // Loading overlay
              if (_isReverseGeocoding || _isSearching)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Address text
        if (_address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.location_pin, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _address,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
