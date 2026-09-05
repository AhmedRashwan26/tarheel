import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final String? district;
  final String? city;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.district,
    this.city,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Requests permissions and retrieves the actual current device position.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  /// Retrieves the actual position and attempts to reverse-geocode to a human-readable Arabic address.
  Future<LocationResult?> getCurrentLocationWithAddress() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final lat = position.latitude;
    final lng = position.longitude;

    String address = '📍 موقعي الفعلي الحالي (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    String? district;
    String? city;

    try {
      // Reverse geocode via OpenStreetMap Nominatim with Arabic locale
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'accept-language': 'ar',
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'TarheelApp/1.0 (support@tarheel.app)'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] ?? addr['neighbourhood'] ?? '';
          district = addr['suburb'] ?? addr['quarter'] ?? addr['neighbourhood'] ?? '';
          city = addr['city'] ?? addr['state'] ?? 'الرياض';

          final parts = <String>[];
          if (road.toString().isNotEmpty) parts.add(road.toString());
          if (district.toString().isNotEmpty && !parts.contains(district)) parts.add(district.toString());
          if (city.toString().isNotEmpty && !parts.contains(city)) parts.add(city.toString());

          if (parts.isNotEmpty) {
            address = parts.join('، ');
          } else if (data['display_name'] != null) {
            address = data['display_name'].toString().split('،').take(3).join('،');
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding notice: $e');
    }

    return LocationResult(
      latitude: lat,
      longitude: lng,
      address: address,
      district: district,
      city: city,
    );
  }

  /// Opens Google Maps with the given coordinates or address
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = label != null && label.isNotEmpty
        ? '$latitude,$longitude($label)'
        : '$latitude,$longitude';
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        return await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to standard maps URL
        final fallbackUrl = Uri.parse('https://maps.google.com/?q=$latitude,$longitude');
        return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
      return false;
    }
  }
}
