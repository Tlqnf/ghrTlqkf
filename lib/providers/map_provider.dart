import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedal/api/report_api.dart';
import 'package:pedal/models/report.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/services/notification_service.dart';
import 'package:pedal/utils/route_utils.dart';
import 'package:pedal/utils/time_formatter.dart';

enum RecordingStatus { idle, recording, paused }

class MapProvider with ChangeNotifier, WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  AuthProvider? _authProvider;

  NLatLng? _currentLocation; // 현재 위치
  NaverMapController? _mapController; // 맵 컨트롤러
  StreamSubscription<Position>? _positionStreamSubscription; // 실시간 위치 정보

  // 경로 지정
  final int _chunkSize = 25;
  final List<List<NLatLng>> _routeChunks = [[]];

  bool _isFollowingUser = true;
  bool _isMapVisible = true;
  bool _isLoading = true;

  RecordingStatus recordingStatus = RecordingStatus.idle;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  String _elapsedTime = '00:00:00';
  double _distance = 0.0;
  double _avgSpeed = 0.0;
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;

  int? _currentRouteId;

  bool get isRecording => recordingStatus == RecordingStatus.recording;
  bool get isPaused => recordingStatus == RecordingStatus.paused;
  bool get isMapVisible => _isMapVisible;
  bool get isLoading => _isLoading;
  bool get isMapReady => _mapController != null;
  String get elapsedTime => _elapsedTime;
  double get distance => _distance;
  double get avgSpeed => _avgSpeed;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  NLatLng? get currentLocation => _currentLocation;
  NaverMapController? get mapController => _mapController;
  bool get isFollowingUser => _isFollowingUser;
  bool get isNavigating => _isNavigating;

  bool _isNavigating = false;
  NPathOverlay? _navigationPath;
  final List<NMarker> _arrowMarkers = [];

  bool _isInitialized = false;

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  void setMapController(NaverMapController controller) {
    _mapController = controller;
  }

  void toggleMapVisibility() {
    _isMapVisible = !_isMapVisible;
    if (_isMapVisible) {
      _positionStreamSubscription?.resume();
    } else {
      _positionStreamSubscription?.pause();
    }
    notifyListeners();
  }

  void togglePause() {
    if (recordingStatus == RecordingStatus.idle) return;
    recordingStatus = (recordingStatus == RecordingStatus.recording)
        ? RecordingStatus.paused
        : RecordingStatus.recording;

    recordingStatus == RecordingStatus.paused
        ? _stopwatch.stop()
        : _stopwatch.start();

    notifyListeners();
  }

  void _setError(String message) {
    debugPrint("MapProvider error: $message");
    _isLoading = false;
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
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);
    await _notificationService.init();
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
        // ignore: deprecated_member_use
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

      if (recordingStatus != RecordingStatus.idle) {
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

    _mapController?.clearOverlays();
    if (_mapController != null && _currentLocation != null) {
      final marker = NMarker(
        id: 'current_location',
        position: _currentLocation!,
        icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
        size: const Size(15, 15),
        anchor: const NPoint(0.5, 0.5),
      );
      _mapController!.addOverlay(marker);
    }

    recordingStatus = RecordingStatus.recording;
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

    // Show initial notification
    _notificationService.showRecordingNotification(
      time: '00:00:00',
      distance: '0.00 km',
      speed: '0.0 km/h',
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedTime = formatTime(_stopwatch.elapsed.inSeconds);

      if (recordingStatus == RecordingStatus.recording) {
        _notificationService.showRecordingNotification(
          time: _elapsedTime,
          distance: '${(_distance / 1000).toStringAsFixed(2)} km',
          speed: '${_currentSpeed.toStringAsFixed(1)} km/h',
        );
      }
      notifyListeners();
    });
    return true;
  }

  Future<Map<String, dynamic>?> stopRecordingAndNavigate() async {
    await _notificationService.cancelNotification();

    if (recordingStatus != RecordingStatus.recording || _authProvider?.token == null) return null;

    _isMapVisible = true;
    _stopwatch.stop();
    _timer?.cancel();

    final distanceInKm = (_distance / 1000).toStringAsFixed(2);
    final elapsedTime = _elapsedTime;
    final avgSpeed = _avgSpeed.toStringAsFixed(1);

    String? snapshotPath;
    final fullRoute = _routeChunks.expand((chunk) => chunk).toList();

    if (_mapController != null) {
      late NCameraUpdate cameraUpdate;

      if (fullRoute.isNotEmpty) {
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

      recenterMap();

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

    recordingStatus = RecordingStatus.idle;
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

  Future<void> startNavigation(List<NLatLng> routeCoords) async {
    if (_mapController == null || routeCoords.isEmpty) return;

    stopNavigation();
    _isNavigating = true;

    // Draw the path
    _navigationPath = NPathOverlay(
      id: 'navigation_path',
      coords: routeCoords,
      width: 6,
      color: Colors.red,
      outlineWidth: 2,
      outlineColor: Colors.white,
    );
    _mapController!.addOverlay(_navigationPath!);

    // Add arrow markers
    final arrowIcon = NOverlayImage.fromAssetImage('assets/image/arrow.svg');
    for (int i = 0; i < routeCoords.length - 1; i += 10) { // Adjust step for density
      final start = routeCoords[i];
      final end = routeCoords[i + 1];
      final angle = _calculateBearing(start, end);

      final arrowMarker = NMarker(
        id: 'arrow_$i',
        position: start,
        icon: arrowIcon,
        size: const Size(24, 24),
        anchor: const NPoint(0.5, 0.5),
        angle: angle,
      );
      _arrowMarkers.add(arrowMarker);
    }
    for (final marker in _arrowMarkers) {
      _mapController!.addOverlay(marker);
    }

    final bounds = NLatLngBounds.from(routeCoords);
    final cameraUpdate = NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(80));
    _mapController!.updateCamera(cameraUpdate);

    notifyListeners();
  }

  void stopNavigation() {
    if (_mapController == null) return;

    _isNavigating = false;
    if (_navigationPath != null) {
      _mapController!.deleteOverlay(_navigationPath!.info);
      _navigationPath = null;
    }
    if (_arrowMarkers.isNotEmpty) {
      for (final marker in _arrowMarkers) {
        _mapController!.deleteOverlay(marker.info);
      }
      _arrowMarkers.clear();
    }
    notifyListeners();
  }

  double _calculateBearing(NLatLng start, NLatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final y = sin(lon2 - lon1) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authProvider == null) return;

    if (!_authProvider!.hasBackgroundPermission) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        if (recordingStatus == RecordingStatus.recording) {
          _stopwatch.stop();
          _positionStreamSubscription?.pause();
        }
      } else if (state == AppLifecycleState.resumed) {
        if (recordingStatus == RecordingStatus.recording && !_stopwatch.isRunning) {
          _stopwatch.start();
          if (_isMapVisible) {
            _positionStreamSubscription?.resume();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.cancelNotification();
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}