import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/utils/route_utils.dart';
import 'package:pedal/utils/time_formatter.dart';

enum RecordingStatus { idle, recording, paused }

class MapProvider with ChangeNotifier, WidgetsBindingObserver {
  NaverMapController? _mapController; // naver_map 컨트롤러
  StreamSubscription<Position>? _positionStreamSubscription; // 실시간 위치 정보
  AuthProvider? _authProvider;

  // 경로 지정
  final int _chunkSize = 25;
  final List<List<NLatLng>> _routeChunks = [[]];

  // 사용자 위치
  NLatLng? _currentUserLocation;
  bool _isFollowing = true;

  // 로딩 관리
  bool _isLoading = false;
  bool _isMapVisible = true;

  // 기록
  RecordingStatus _recordingStatus = RecordingStatus.idle;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _time = "00:00:00"; // format 형식
  DateTime? _lastTimestamp;

  double _distance = 0.0; // km 단위
  double _avgSpeed = 0.0; // km/h 단위
  double _currentSpeed = 0.0;
  double _maxSpeed = 0.0;

  NPathOverlay? _navigationPath;
  final List<NMarker> _arrowMarkers = [];

  // 백그라운드 알림
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // getter 함수
  bool get isLoading => _isLoading;
  bool get isFollowing => _isFollowing;
  bool get isMapVisible => _isMapVisible;
  bool get isRecording => _recordingStatus == RecordingStatus.recording;
  bool get isPaused => _recordingStatus == RecordingStatus.paused;
  NLatLng? get currentUserLocation => _currentUserLocation;
  NaverMapController? get mapController => _mapController;
  String get time => _time;
  double get distance => _distance;
  double get avgSpeed => _avgSpeed;
  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;

  // setter 함수
  set authProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  set mapController(NaverMapController mapController) {
    _mapController = mapController;
    notifyListeners();
  }

  set isFollowingUser(bool isFollowing) {
    _isFollowing = isFollowing;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 앱이 백그라운드로 가거나 종료될 때
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 기록 중이 아니면 알림 취소
      if (_recordingStatus == RecordingStatus.idle) {
        _cancelTrackingNotification();
      }
    }

    // 앱이 포그라운드로 돌아올 때
    if (state == AppLifecycleState.resumed) {
      // 기록 중이 아니면 알림 취소 (혹시 남아있을 수 있으므로)
      if (_recordingStatus == RecordingStatus.idle) {
        _cancelTrackingNotification();
      }
    }
  }

  void mapVisibility() {
    _isMapVisible = !_isMapVisible;
    if (_isMapVisible) {
      _positionStreamSubscription?.resume();
    } else {
      _positionStreamSubscription?.pause();
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    await initNotification();
    _isLoading = true;
    notifyListeners();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return;
    }

    // 권한 허용 케이스 분류
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return;
    }

    // 사용자 위치 가져오기
    Position? lastPos = await Geolocator.getLastKnownPosition(); // 1차로 불러오기
    if (lastPos != null) {
      _currentUserLocation = NLatLng(lastPos.latitude, lastPos.longitude);
      _isLoading = false;
      notifyListeners();
    }
    try {
      Position currentPos = await Geolocator.getCurrentPosition(); // 최종 불러오기
      _currentUserLocation = NLatLng(currentPos.latitude, currentPos.longitude);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("유저 정보를 불러오는데 실패함 $e");
    }

    // 위치 스트림 구독하기
    positionStream();
    notifyListeners();
  }

  Future<void> initNotification() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );
    await _notifications.initialize(initSettings);
  }

  // 실시간 위치 스트림 구독
  Future<void> positionStream() async {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen((Position pos) {
          if (_mapController == null) return;
          // 새로운 위치, 속도 정보 저장
          final newPoint = NLatLng(pos.latitude, pos.longitude);
          // 내 위치 갱신
          _currentUserLocation = newPoint;

          final marker = NMarker(
            id: "user_pos",
            position: newPoint,
            icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
            size: const Size(12, 12),
            anchor: const NPoint(0.5, 0.5),
          );
          // 사용자 위치 표시 (overlay)
          _mapController?.addOverlay(marker);

          if (_recordingStatus == RecordingStatus.recording) {
            recordingLogic(newPoint, pos);
          }
        });
  }

  void recordingLogic(NLatLng newPoint, Position pos) {
    final lastPoint = _currentUserLocation;
    final lastTimestamp = _lastTimestamp;
    if (lastPoint == null) return;

    // 첫 위치일 경우 초기화만 하고 종료
    if (lastTimestamp == null) {
      _currentUserLocation = newPoint;
      _lastTimestamp = pos.timestamp;
      return;
    }

    // 거리 계산 km로 표시
    final distance =
        Geolocator.distanceBetween(
          lastPoint.latitude,
          lastPoint.longitude,
          newPoint.latitude,
          newPoint.longitude,
        ) *
        0.001;

    if (distance > 0.001 && distance < 0.5) {
      _distance += distance;
    }

    // 현재, 최고 속력 업데이트
    _currentSpeed = pos.speed * 3.6;
    final instantSpeed = pos.speed * 3.6; // km/h
    if (instantSpeed > _maxSpeed && instantSpeed < 100) _maxSpeed = instantSpeed;

    // 평균 속력 업데이트
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    if (elapsedSeconds > 0) {
      _avgSpeed = (_distance / elapsedSeconds) * 3600; // km/h
    }

    // 현재 위치와 timestamp 갱신
    _currentUserLocation = newPoint;
    _lastTimestamp = pos.timestamp;

    _addPointToRoute(newPoint);
    notifyListeners();
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

  Future<void> _showTrackingNotification() async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'ride_tracking_channel',
      '주행 기록',
      channelDescription: '라이딩 중 상태를 표시합니다.',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showWhen: false,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      0,
      '라이딩 기록 중',
      '시간: $_time | 거리: ${_distance.toStringAsFixed(2)} km | 속도: ${_currentSpeed.toStringAsFixed(1)} km/h', // 속도 추가
      notificationDetails,
    );
  }

  Future<void> _cancelTrackingNotification() async {
    await _notifications.cancel(0);
  }

  // 기록 시작
  Future<void> startRecording() async {
    if (_authProvider?.token == null) {
      debugPrint("인증 정보가 존재하지 않습니다.");
      return;
    }
    _recordingStatus = RecordingStatus.recording;

    // 마커 초기화
    await _mapController?.clearOverlays();
    if (_mapController != null && _currentUserLocation != null) {
      final marker = NMarker(
        id: 'user_pos',
        position: _currentUserLocation!,
        icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
        size: const Size(12, 12),
        anchor: const NPoint(0.5, 0.5),
      );
      await _mapController!.addOverlay(marker);
    }

    _lastTimestamp = null;
    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _time = formatTime(_stopwatch.elapsed.inSeconds);
      _showTrackingNotification();
      notifyListeners();
    });
    notifyListeners();
  }

  // 일시 정지
  void pauseAndRecording() {
    if (_recordingStatus == RecordingStatus.idle) {
      debugPrint('Cannot pause/resume when not recording');
      return;
    }

    final oldStatus = _recordingStatus;
    _recordingStatus = (_recordingStatus == RecordingStatus.recording)
        ? RecordingStatus.paused
        : RecordingStatus.recording;

    _recordingStatus == RecordingStatus.paused
        ? _stopwatch.stop()
        : _stopwatch.start();

    debugPrint('Status changed: $oldStatus -> $_recordingStatus');
    debugPrint('isRecording: $isRecording, isPaused: $isPaused');
    notifyListeners();
  }

  // 기록 종료
  Future<Map<String, dynamic>?> stopRecording() async {
    if (_recordingStatus == RecordingStatus.idle ||
        _authProvider?.token == null) {
      return null;
    }

    _stopwatch.stop();
    _timer?.cancel();

    final distance = _distance;
    final time = _time;
    final avgSpeed = _avgSpeed;
    final maxSpeed = _maxSpeed;
    final fullRoute = _routeChunks.expand((chunk) => chunk).toList();
    final routeCoords = fullRoute
        .map((p) => [p.latitude, p.longitude])
        .toList();

    String? snapshotPath;
    if (_mapController != null) {
      late NCameraUpdate cameraUpdate;

      if (fullRoute.isNotEmpty) {
        final bounds = NLatLngBounds.from(fullRoute);
        cameraUpdate = NCameraUpdate.fitBounds(
          bounds,
          padding: const EdgeInsets.all(80),
        );
        final double distanceMeters = calculateRouteDistance(fullRoute);
        int durationMs = (distanceMeters / 500).clamp(500, 3000).toInt();
        cameraUpdate.setAnimation(
          animation: NCameraAnimation.linear,
          duration: Duration(milliseconds: durationMs),
        );
      } else {
        cameraUpdate = NCameraUpdate.withParams(target: _currentUserLocation);
        cameraUpdate.setAnimation(animation: NCameraAnimation.none);
      }
      await _mapController!.updateCamera(cameraUpdate);
      await Future.delayed(const Duration(milliseconds: 500));

      final imageFile = await _mapController!.takeSnapshot();
      snapshotPath = imageFile.path;

      recenterMap();

      await _mapController?.clearOverlays();
      if (_currentUserLocation != null) {
        final marker = NMarker(
          id: 'user_pos',
          position: _currentUserLocation!,
          icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
          size: const Size(12, 12),
          anchor: const NPoint(0.5, 0.5),
        );
        _mapController!.addOverlay(marker);
      }
    }

    return {
      'initialDistance': distance,
      'initialTime': time,
      'initialAvgSpeed': avgSpeed,
      'initialMaxSpeed': maxSpeed,
      'mapImagePath': snapshotPath,
      'routeCoords': routeCoords,
    };
  }

  void resetRecording() async {
    // 프로세스 종료
    _stopwatch.stop();
    _timer?.cancel();
    _isMapVisible = true;
    _recordingStatus = RecordingStatus.idle;
    _stopwatch.reset();
    _distance = 0.0;
    _avgSpeed = 0.0;
    _time = '00:00:00';
    _lastTimestamp = null;
    _currentSpeed = 0.0;
    _maxSpeed = 0.0;
    _routeChunks.clear();
    _routeChunks.add([]);
    _cancelTrackingNotification();
    notifyListeners();
  }

  // 중앙 정렬
  void recenterMap() {
    if (_currentUserLocation != null && _mapController != null) {
      _isFollowing = true;
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: _currentUserLocation!,
          zoom: 16.5,
        ),
      );
      notifyListeners();
    }
  }

  // 네비게이션 기능들 todo
  Future<void> startNavigation(List<NLatLng> routeCoords) async {
    if (_mapController == null || routeCoords.isEmpty) return;

    // 디버그: 경로 좌표 개수 확인
    debugPrint('=== Navigation Start ===');
    debugPrint('Total route coordinates: ${routeCoords.length}');

    // 최소 2개의 좌표가 필요
    if (routeCoords.length < 2) {
      debugPrint('Error: Need at least 2 coordinates for path overlay');
      return;
    }

    // 처음 몇 개의 좌표 출력
    debugPrint(
      'First coordinate: ${routeCoords.first.latitude}, ${routeCoords.first.longitude}',
    );
    debugPrint(
      'Last coordinate: ${routeCoords.last.latitude}, ${routeCoords.last.longitude}',
    );
    if (routeCoords.length > 2) {
      debugPrint(
        'Second coordinate: ${routeCoords[1].latitude}, ${routeCoords[1].longitude}',
      );
    }

    // Draw the path
    _navigationPath = NPathOverlay(
      id: 'navigation_path',
      coords: routeCoords,
      width: 6,
      color: Colors.red,
      outlineWidth: 2,
      outlineColor: Colors.white,
    );

    try {
      await _mapController!.addOverlay(_navigationPath!);
      debugPrint('Path overlay added successfully');
    } catch (e) {
      debugPrint('Error adding path overlay: $e');
      return;
    }

    // Add arrow markers
    try {
      final arrowIcon = NOverlayImage.fromAssetImage('assets/image/arrow.svg');
      int arrowCount = 0;

      for (int i = 0; i < routeCoords.length - 1; i += 10) {
        // Adjust step for density
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
        arrowCount++;
      }

      debugPrint('Creating $arrowCount arrow markers');

      for (final marker in _arrowMarkers) {
        await _mapController!.addOverlay(marker);
      }

      debugPrint('All arrow markers added successfully');
    } catch (e) {
      debugPrint('Error adding arrow markers: $e');
    }

    // 카메라 이동
    try {
      final bounds = NLatLngBounds.from(routeCoords);
      final cameraUpdate = NCameraUpdate.fitBounds(
        bounds,
        padding: const EdgeInsets.all(80),
      );
      await _mapController!.updateCamera(cameraUpdate);
      debugPrint('Camera updated to fit route bounds');
    } catch (e) {
      debugPrint('Error updating camera: $e');
    }

    debugPrint('=== Navigation Started Successfully ===');
    notifyListeners();
  }

  void stopNavigation() {
    if (_mapController == null) return;

    debugPrint('=== Stopping Navigation ===');

    if (_navigationPath != null) {
      try {
        _mapController!.deleteOverlay(_navigationPath!.info);
        debugPrint('Path overlay deleted');
      } catch (e) {
        debugPrint('Error deleting path overlay: $e');
      }
      _navigationPath = null;
    }

    if (_arrowMarkers.isNotEmpty) {
      debugPrint('Deleting ${_arrowMarkers.length} arrow markers');
      try {
        for (final marker in _arrowMarkers) {
          _mapController!.deleteOverlay(marker.info);
        }
        debugPrint('All arrow markers deleted');
      } catch (e) {
        debugPrint('Error deleting arrow markers: $e');
      }
      _arrowMarkers.clear();
    }

    debugPrint('=== Navigation Stopped ===');
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
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _timer?.cancel();
    _mapController?.dispose();
    _cancelTrackingNotification();
    super.dispose();
  }
}
