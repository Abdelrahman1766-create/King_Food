import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../services/location_service.dart';
import '../utils/i18n.dart';

class GisMapPicker extends StatefulWidget {
  const GisMapPicker({super.key, this.initialLocation});

  final MapLocation? initialLocation;

  @override
  State<GisMapPicker> createState() => _GisMapPickerState();
}

class _GisMapPickerState extends State<GisMapPicker> {
  static bool _androidViewSurface = true;
  YandexMapController? _controller;
  MapLocation? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = true;
  late final TextEditingController _searchController;
  bool _isSearching = false;
  String? _searchError;
  final List<_SearchResult> _searchResults = [];
  bool _mapLoadingFailed = false;
  Timer? _mapLoadTimer;
  // Reverse geocoding from tap can crash on some Android builds after Flutter upgrades.
  // We now fetch address for selected point immediately (as the feature is required).

  @override
  void initState() {
    super.initState();
    AndroidYandexMap.useAndroidViewSurface = _androidViewSurface;
    _searchController = TextEditingController();
    _initializeLocation();
    _startMapLoadTimeout();
  }

  @override
  void dispose() {
    _mapLoadTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final fallback =
        widget.initialLocation ??
        const MapLocation(latitude: 55.8304, longitude: 49.0661);

    if (!mounted) return;
    setState(() {
      _selectedLocation = fallback;
      _selectedAddress = _formatCoords(fallback);
      _isLoading = false;
    });

    final currentLocation = await LocationService()
        .getCurrentLocation()
        .timeout(const Duration(seconds: 6), onTimeout: () => null);

    if (!mounted) return;
    final initial = widget.initialLocation ?? currentLocation ?? fallback;

    if (initial != _selectedLocation) {
      setState(() {
        _selectedLocation = initial;
        _selectedAddress = _formatCoords(initial);
      });
    }

    unawaited(_fetchAddress(initial, fallback: _formatCoords(initial)));

    if (_controller != null) {
      await _moveCameraTo(initial, zoom: 16);
    }
  }

  void _startMapLoadTimeout() {
    _mapLoadTimer?.cancel();
    _mapLoadTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _controller == null) {
        setState(() => _mapLoadingFailed = true);
      }
    });
  }

  Future<void> _fetchAddress(
    MapLocation location, {
    required String fallback,
  }) async {
    try {
      final address = await LocationService()
          .getAddressFromCoordinates(location)
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      setState(
        () => _selectedAddress = (address == null || address.trim().isEmpty)
            ? fallback
            : address.trim(),
      );
      return;
    } catch (_) {
      // Fall back to coordinates when reverse geocoding fails.
    }
    if (!mounted) return;
    setState(() => _selectedAddress = fallback);
  }

  Future<void> _moveCameraTo(MapLocation location, {double zoom = 16}) async {
    if (_controller == null) return;
    await _controller!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
          zoom: zoom,
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.4,
      ),
    );
  }

  List<MapObject> _buildMapObjects() {
    if (_selectedLocation == null) return const [];
    final point = Point(
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    return [
      CircleMapObject(
        mapId: const MapObjectId('selected_circle'),
        circle: Circle(center: point, radius: 12),
        strokeColor: Colors.red,
        strokeWidth: 2,
        fillColor: Colors.red.withValues(alpha: 0.2),
      ),
    ];
  }

  Future<void> _selectPoint(Point point) async {
    try {
      if (!mounted) return;

      // Validate point
      if (point.latitude == 0 && point.longitude == 0) {
        return;
      }

      final location = MapLocation(
        latitude: point.latitude,
        longitude: point.longitude,
      );

      if (!mounted) return;
      setState(() {
        _selectedLocation = location;
        _selectedAddress = _formatCoords(location);
      });

      // Fetch address by coordinates (tap) and update display name.
      await _fetchAddress(location, fallback: _formatCoords(location));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              context,
              'Error selecting location. Try again.',
              'Ошибка при выборе места. Попробуйте снова.',
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    final current = await LocationService().getCurrentLocation();
    if (!mounted) return;
    if (current == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              context,
              'Unable to access your current location. Check GPS and permissions.',
              'Не удалось получить текущее местоположение. Проверьте GPS и разрешения.',
            ),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = current;
      _selectedAddress = _formatCoords(current);
    });
    await _fetchAddress(current, fallback: _formatCoords(current));
    if (!mounted) return;
    await _moveCameraTo(current, zoom: 16);
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults.clear();
    });

    final fallback =
        _selectedLocation ??
        const MapLocation(latitude: 55.8304, longitude: 49.0661);
    final geometry = Geometry.fromPoint(
      Point(latitude: fallback.latitude, longitude: fallback.longitude),
    );

    try {
      final (session, resultFuture) = await YandexSearch.searchByText(
        searchText: trimmed,
        geometry: geometry,
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          resultPageSize: 8,
        ),
      );
      final result = await resultFuture;
      await session.close();

      if (result.error != null) {
        if (!mounted) return;
        setState(() {
          _searchError = result.error.toString();
        });
        return;
      }

      final items = result.items ?? [];
      final results = <_SearchResult>[];
      for (final item in items) {
        final pointGeometry = item.geometry.firstWhere(
          (g) => g.point != null,
          orElse: () => Geometry.fromPoint(
            Point(latitude: fallback.latitude, longitude: fallback.longitude),
          ),
        );
        final point = pointGeometry.point;
        if (point == null) continue;
        results.add(
          _SearchResult(
            title: item.name,
            subtitle: item.toponymMetadata?.address.formattedAddress,
            point: point,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _searchResults
          ..clear()
          ..addAll(results);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectSearchResult(_SearchResult result) async {
    final location = MapLocation(
      latitude: result.point.latitude,
      longitude: result.point.longitude,
    );
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _selectedAddress = result.subtitle ?? result.title;
      _searchResults.clear();
    });
    await _moveCameraTo(location, zoom: 16);
  }

  void _openAppSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            context,
            'Open settings manually: Settings → Apps → king_food → Permissions → Location',
            'Откройте настройки вручную: Настройки → Приложения → king_food → Разрешения → Геолокация',
          ),
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showManualLocationDialog() {
    final latController = TextEditingController(
      text: _selectedLocation?.latitude.toStringAsFixed(6) ?? '55.830400',
    );
    final lngController = TextEditingController(
      text: _selectedLocation?.longitude.toStringAsFixed(6) ?? '49.066100',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          t(context, 'Set location manually', 'Указать локацию вручную'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t(context, 'Enter coordinates:', 'Введите координаты:')),
            const SizedBox(height: 12),
            TextField(
              controller: latController,
              decoration: InputDecoration(
                labelText: t(context, 'Latitude', 'Широта'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              decoration: InputDecoration(
                labelText: t(context, 'Longitude', 'Долгота'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t(context, 'Cancel', 'Отмена')),
          ),
          ElevatedButton(
            onPressed: () async {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              if (lat == null || lng == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t(
                        context,
                        'Please enter valid coordinates',
                        'Введите корректные координаты',
                      ),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newLocation = MapLocation(latitude: lat, longitude: lng);
              if (!mounted) return;
              setState(() {
                _selectedLocation = newLocation;
                _selectedAddress = _formatCoords(newLocation);
              });
              await _fetchAddress(
                newLocation,
                fallback: _formatCoords(newLocation),
              );
              if (!mounted) return;
              await _moveCameraTo(newLocation, zoom: 16);

              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
              }
            },
            child: Text(t(context, 'Confirm', 'Подтвердить')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedLocation;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final verticalPadding = isSmallScreen ? 10.0 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'Choose location', 'Выберите место')),
        actions: [
          SizedBox(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            child: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _useCurrentLocation,
              tooltip: t(
                context,
                'Use my current location',
                'Моё местоположение',
              ),
            ),
          ),
          SizedBox(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            child: IconButton(
              icon: const Icon(Icons.edit_location_alt),
              onPressed: _showManualLocationDialog,
              tooltip: t(context, 'Set manually', 'Указать вручную'),
            ),
          ),
          SizedBox(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openAppSettings,
              tooltip: t(context, 'Open settings', 'Открыть настройки'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(horizontalPadding),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(
                        Icons.map,
                        color: Colors.blue,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: Text(
                          t(
                            context,
                            'Tap the map to select the location precisely.',
                            'Нажмите на карту, чтобы точно выбрать место.',
                          ),
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: _runSearch,
                          decoration: InputDecoration(
                            hintText: t(
                              context,
                              'Search address',
                              'Поиск адреса',
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: isSmallScreen ? 20 : 24,
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: isSmallScreen ? 18 : 20,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchResults.clear();
                                          _searchError = null;
                                        });
                                      },
                                    ),
                                  ),
                            border: const OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: isSmallScreen ? 8 : 10,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      FilledButton.icon(
                        onPressed: _isSearching
                            ? null
                            : () => _runSearch(_searchController.text),
                        icon: _isSearching
                            ? SizedBox(
                                width: isSmallScreen ? 14 : 16,
                                height: isSmallScreen ? 14 : 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(Icons.search, size: isSmallScreen ? 18 : 20),
                        label: Text(
                          t(context, 'Search', 'Поиск'),
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_searchError != null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 4,
                    ),
                    child: Text(
                      t(
                        context,
                        'Search failed. Try a different query.',
                        'Поиск не удался. Попробуйте другой запрос.',
                      ),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: isSmallScreen ? 150 : 200,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            dense: isSmallScreen,
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.subtitle == null
                                ? null
                                : Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                  ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _mapLoadingFailed
                        ? Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.map,
                                    size: 48,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    t(
                                      context,
                                      'Map loading failed. Tap to retry.',
                                      'Не удалось загрузить карту. Нажмите, чтобы повторить.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _mapLoadingFailed = false;
                                      });
                                      AndroidYandexMap.useAndroidViewSurface =
                                          !_androidViewSurface;
                                      _androidViewSurface =
                                          !_androidViewSurface;
                                      _startMapLoadTimeout();
                                    },
                                    child: Text(
                                      t(
                                        context,
                                        'Retry (legacy mode)',
                                        'Повторить (легаси режим)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : YandexMap(
                            onMapCreated: (controller) async {
                              _mapLoadTimer?.cancel();
                              if (mounted) {
                                setState(() {
                                  _mapLoadingFailed = false;
                                });
                              }
                              _controller = controller;
                              try {
                                await _controller!.toggleUserLayer(
                                  visible: true,
                                  headingEnabled: true,
                                  autoZoomEnabled: false,
                                );
                              } catch (_) {
                                // Keep map working even if user layer fails on some devices.
                              }
                              if (_selectedLocation != null) {
                                await _moveCameraTo(
                                  _selectedLocation!,
                                  zoom: 16,
                                );
                              }
                            },

                            onMapTap: (point) {
                              try {
                                _selectPoint(point);
                              } catch (e) {
                                // Handle error silently
                              }
                            },
                            mapObjects: _buildMapObjects(),
                          ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(context, 'Selected location:', 'Выбранное место:'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 3 : 4),
                      Text(
                        selected != null
                            ? '${t(context, 'Lat', 'Широта')}: ${selected.latitude.toStringAsFixed(6)}, ${t(context, 'Lng', 'Долгота')}: ${selected.longitude.toStringAsFixed(6)}'
                            : t(
                                context,
                                'No location selected',
                                'Место не выбрано',
                              ),
                        style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedAddress != null) ...[
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          _selectedAddress!,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 40 : 48,
                  child: ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () {
                            Navigator.of(context).pop(selected);
                          },
                    child: Text(
                      t(context, 'Confirm location', 'Подтвердить'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCoords(MapLocation location) {
    return '${t(context, 'Lat', 'Широта')}: ${location.latitude.toStringAsFixed(6)}, '
        '${t(context, 'Lng', 'Долгота')}: ${location.longitude.toStringAsFixed(6)}';
  }
}

class _SearchResult {
  final String title;
  final String? subtitle;
  final Point point;

  const _SearchResult({
    required this.title,
    required this.point,
    this.subtitle,
  });
}
