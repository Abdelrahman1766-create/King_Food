import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart' as ymk;

class MapLocation {
  final double latitude;
  final double longitude;

  const MapLocation({required this.latitude, required this.longitude});
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();

  Future<bool> _checkServiceEnabled() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _checkPermissionGranted() async {
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    } else if (permissionGranted == PermissionStatus.deniedForever) {
      return false;
    }
    return true;
  }

  Future<MapLocation?> getCurrentLocation() async {
    try {
      final serviceEnabled = await _checkServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      final permissionGranted = await _checkPermissionGranted();
      if (!permissionGranted) {
        return null;
      }

      final locationData = await _location.getLocation();
      if (locationData.latitude == null || locationData.longitude == null) {
        return null;
      }

      return MapLocation(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(MapLocation coordinates) async {
    try {
      final result = await _reverseSearch(coordinates);
      return result?.formattedAddress ?? result?.name;
    } catch (e) {
      return null;
    }
  }

  /// Get place name from 2GIS API (Russian location service)
  Future<String?> getPlaceNameFromCoordinates(MapLocation coordinates) async {
    try {
      final result = await _reverseSearch(coordinates);
      return result?.name ?? result?.formattedAddress;
    } catch (e) {
      return null;
    }
  }

  Future<MapLocation?> getCoordinatesFromAddress(String address) async {
    try {
      // For now, return Kazan coordinates as default
      return const MapLocation(latitude: 55.8304, longitude: 49.0661);
    } catch (e) {
      return null;
    }
  }
}

class _ReverseSearchResult {
  final String? name;
  final String? formattedAddress;

  const _ReverseSearchResult({this.name, this.formattedAddress});
}

Future<_ReverseSearchResult?> _reverseSearch(MapLocation coordinates) async {
  try {
    final point = ymk.Point(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
    final geometry = ymk.Geometry.fromPoint(point);
    // Use searchByText only to avoid searchByPoint MissingPluginException
    // on some yandex_mapkit/native combinations.
    final searchResult = await ymk.YandexSearch.searchByText(
      searchText: '${coordinates.latitude}, ${coordinates.longitude}',
      geometry: geometry,
      searchOptions: const ymk.SearchOptions(
        searchType: ymk.SearchType.geo,
        resultPageSize: 1,
      ),
    );

    final (session, resultFuture) = searchResult;
    final result = await resultFuture;
    await session.close();

    if (result.error != null) {
      return null;
    }

    final item = result.items != null && result.items!.isNotEmpty
        ? result.items!.first
        : null;
    if (item == null) {
      return null;
    }

    final formatted = item.toponymMetadata?.address.formattedAddress;
    return _ReverseSearchResult(name: item.name, formattedAddress: formatted);
  } on MissingPluginException {
    return null;
  } catch (_) {
    return null;
  }
}
