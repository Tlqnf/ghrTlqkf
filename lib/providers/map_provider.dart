import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pedal/api/report_api.dart';
import 'package:pedal/models/report.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/utils/route_utils.dart';
import 'package:pedal/utils/time_formatter.dart';

class MapProvider with ChangeNotifier {
  AuthProvider? _authProvider;

  NLatLng? _currentLocation;
  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  final int _chunkSize = 25;
  final List<List<NLatLng>> _routeChunks = [[]];

  bool _isFollowingUser = true;
  bool _isMapVisible = true;
  bool _isLoading = true;
  bool _isMapReady = false;

  bool _isRecording = false;
  bool _isPaused = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  String _elapsedTime = '00:00:00';
  double _distance = 0.0;
  double _avgSpeed = 0.0;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;

  int? _currentRouteId;
  BannerAd? _bannerAd;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  bool get isMapVisible => _isMapVisible;
  bool get isLoading => _isLoading;
  bool get isMapReady => _isMapReady;
  String get elapsedTime => _elapsedTime;
  double get distance => _distance;
  double get avgSpeed => _avgSpeed;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  NLatLng? get currentLocation => _currentLocation;
  NaverMapController? get mapController => _mapController;
  BannerAd? get bannerAd => _bannerAd;
  bool get isFollowingUser => _isFollowingUser;

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  void setMapController(NaverMapController controller) {
    _mapController = controller;
  }

  void setMapReady(bool isReady) {
    _isMapReady = isReady;
    notifyListeners();
  }

  void toggleMapVisibility() {
    _isMapVisible = !_isMapVisible;
    notifyListeners();
  }

  void togglePause() {
    if (!_isRecording) return;
    _isPaused = !_isPaused;
    if (_isPaused) {
      _stopwatch.stop();
    } else {
      _stopwatch.start();
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void setIsFollowingUser(bool isFollowing) {
    _isFollowingUser = isFollowing;
    notifyListeners();
  }

  void recenterMap() {
    if (_currentLocation != null && _mapController != null) {
      _isFollowingUser = true;
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: _currentLocation!,
          zoom: 16.5,
        ),
      );
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setError('Location services are disabled.');
      return;
    }

    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setError('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setError('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // Initial location fetching
    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null) {
      _currentLocation = NLatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
      _isLoading = false;
      notifyListeners();
    }

    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
      _currentLocation = NLatLng(currentPosition.latitude, currentPosition.longitude);
      _isLoading = false;

      if (_mapController != null && _currentLocation != null) {
        final cameraUpdate = NCameraUpdate.scrollAndZoomTo(target: _currentLocation!, zoom: 16.5);
        _mapController?.updateCamera(cameraUpdate);
      }
      notifyListeners();
    } catch (e) {
      if (_currentLocation == null) {
        _setError("Failed to get current location.");
      }
    }

    // Start listening to Geolocator stream
    _positionStreamSubscription?.cancel(); // Cancel any previous subscription
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Receive updates even for small movements
      ),
    ).listen((Position position) {

      final newPoint = NLatLng(position.latitude, position.longitude);
      final currentSpeedKmh = position.speed * 3.6;

      final marker = NMarker(
        id: 'current_location',
        position: newPoint,
        icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
        size: const Size(15, 15),
        anchor: const NPoint(0.5, 0.5),
      );
      _mapController?.addOverlay(marker);

      if (_isRecording && !_isPaused) {
        final lastPoint = _currentLocation;
        if (lastPoint != null) {
          final distance = Geolocator.distanceBetween(
            lastPoint.latitude,
            lastPoint.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
          if (distance >= 0 && distance < 100) { // Filter out large jumps
            _distance += distance;
          }
        }

        final elapsedSec = _stopwatch.elapsed.inSeconds;
        if (_distance > 0 && elapsedSec > 0) {
          _avgSpeed = (_distance / elapsedSec) * 3.6;
        }

        if (currentSpeedKmh > _maxSpeed) _maxSpeed = currentSpeedKmh;
        _addPointToRoute(newPoint);
      }

      _currentLocation = newPoint;
      _currentSpeed = currentSpeedKmh;
      _isLoading = false;

      if (_isFollowingUser && _isMapVisible && _mapController != null) {
        _mapController!.getCameraPosition().then((p) {
          final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
            target: newPoint,
            zoom: p.zoom,
          );
          _mapController!.updateCamera(cameraUpdate);
        });
      }
      notifyListeners();
    });
  }

  void _addPointToRoute(NLatLng point) {
    var lastChunk = _routeChunks.last;
    if (lastChunk.length >= _chunkSize) {
      final NLatLng lastPoint = lastChunk.last;
      _routeChunks.add([lastPoint]);
      lastChunk = _routeChunks.last;
    }
    lastChunk.add(point);

    if (_mapController != null && lastChunk.length >= 2) {
      final chunkIndex = _routeChunks.length - 1;
      final pathOverlay = NPathOverlay(
        id: 'route_chunk_$chunkIndex',
        coords: lastChunk,
        width: 6,
        color: Colors.blue,
        outlineWidth: 2,
        outlineColor: Colors.white,
      );
      _mapController!.addOverlay(pathOverlay);
    }

    notifyListeners();
  }

  Future<bool> startRecording() async {
    if (_authProvider?.token == null) {
      _setError("Authentication information is missing. Please log in again.");
      return false;
    }

    final int newRouteId = await RouteApi.getRouteId(_authProvider!.token!);
    _currentRouteId = newRouteId;

    if (_currentRouteId == null) {
      _setError("Failed to get route ID. Please try again.");
      return false;
    }

    _mapController?.clearOverlays();
    if (_currentLocation != null) {
      final marker = NMarker(
        id: 'current_location',
        position: _currentLocation!,
        icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
        size: const Size(15, 15),
        anchor: const NPoint(0.5, 0.5),
      );
      _mapController!.addOverlay(marker);
    }

    _isRecording = true;
    _isPaused = false;
    _distance = 0.0;
    _avgSpeed = 0.0;
    _elapsedTime = '00:00:00';
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _routeChunks.clear();
    _routeChunks.add([]);

    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedTime = formatTime(_stopwatch.elapsed.inSeconds);
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>?> stopRecordingAndNavigate() async {
    if (!_isRecording || _authProvider?.token == null) return null;

    _isMapVisible = true;
    _stopwatch.stop();
    _timer?.cancel();

    final distanceInKm = (_distance / 1000).toStringAsFixed(2);
    final elapsedTime = _elapsedTime;
    final avgSpeed = _avgSpeed.toStringAsFixed(1);

    String? snapshotPath;
    final fullRoute = _routeChunks.expand((chunk) => chunk).toList();
    late NCameraUpdate cameraUpdate;

    if (fullRoute.isNotEmpty && _mapController != null) {
      final bounds = NLatLngBounds.from(fullRoute);
      cameraUpdate = NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(80));
      final double distanceMeters = calculateRouteDistance(fullRoute);
      int durationMs = (distanceMeters / 500).clamp(500, 3000).toInt();
      cameraUpdate.setAnimation(
        animation: NCameraAnimation.linear,
        duration: Duration(milliseconds: durationMs),
      );
    } else {
      cameraUpdate = NCameraUpdate.withParams(target: _currentLocation);
      cameraUpdate.setAnimation(animation: NCameraAnimation.none);
    }
    await _mapController!.updateCamera(cameraUpdate);
    await Future.delayed(const Duration(milliseconds: 500));

    final imageFile = await _mapController!.takeSnapshot();
    snapshotPath = imageFile.path;

    _mapController?.clearOverlays();
    if (_currentLocation != null) {
      final marker = NMarker(
        id: 'current_location',
        position: _currentLocation!,
        icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
        size: const Size(15, 15),
        anchor: const NPoint(0.5, 0.5),
      );
      _mapController!.addOverlay(marker);
    }

    final reportId = await ReportApi.createReport(
        ReportCreate(
          routeId: _currentRouteId!,
          healthTime: timeToInt(_elapsedTime),
          distance: _distance / 1000,
          averageSpeed: _avgSpeed,
          highestSpeed: _maxSpeed,
        ),
        _authProvider!.token!
    );

    final routeCoords = fullRoute.map((p) => [p.latitude, p.longitude]).toList();

    _isRecording = false;
    _isPaused = false;
    _stopwatch.reset();
    _distance = 0.0;
    _avgSpeed = 0.0;
    _elapsedTime = '00:00:00';
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _routeChunks.clear();
    _routeChunks.add([]);
    notifyListeners();

    return {
      'reportId': reportId,
      'routeId': _currentRouteId,
      'initialDistance': distanceInKm,
      'initialTime': elapsedTime,
      'initialAvgSpeed': avgSpeed,
      'mapImagePath': snapshotPath,
      'routeCoords': routeCoords,
    };
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}