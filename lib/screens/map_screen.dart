import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedal/api/report_api.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/models/report.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/utils/time_formatter.dart';
import 'package:pedal/widgets/map/modal/navigation_list_modal.dart';
import 'package:pedal/widgets/map/overlay/pre_recording_overlay.dart';
import 'package:pedal/widgets/map/overlay/recording_overlay.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  NLatLng? _currentLocation; // 최근 경로
  NaverMapController? _mapController;//네이버 지도 컨트롤러
  StreamSubscription<Position>? _positionStreamSubscription; // 이벤트 구독
  final int _chunkSize = 25; // 경로 생성 조작
  List<List<NLatLng>> _routeChunks = [[]]; // route 저장
  bool _isFollowingUser = true; // 유저 표시
  bool _isMapVisible = true; // 맵 표시
  bool _isLoading = true; // 데이터 로딩
  bool _isMapReady = false; // Variable to control map loading
  NMarker? _currentMarker; // 사용자 위치 마커

  // Recording State
  bool _isRecording = false;
  bool _isPaused = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  double _distance = 0.0; // in meters
  double _avgSpeed = 0.0; // in km/h
  double _currentSpeed = 0.0; // in km/h
  double _maxSpeed = 0.0; // in km/h

  // Save Route
  int? _currentRouteId;

  @override
  void initState() {
    super.initState();
    _initializeLocationStream();

    // Delay map loading to prevent transition animation conflicts
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // 사용자 위치 정보 불러오기 (권한 허용)
  Future<void> _initializeLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied');
      return;
    }

    // 사용자의 최신 위치 가져오기
    Position? currentPosition = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    _currentLocation = NLatLng(currentPosition.latitude, currentPosition.longitude);

    // 실시간 위치 스트림 시작하기
    _startLocationStream();
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10, // 10m 마다 GPS 가져오기
    );

    // 위치 스트림 구독
    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position position) async {
            if (!mounted) return;
            final newPoint = NLatLng(position.latitude, position.longitude);

            // 현재 속도 (m/s → km/h)
            final currentSpeedKmh =
            (position.speed >= 0 && position.speed < 150) ? position.speed * 3.6 : 0.0;

            // 내 위치 마커 업데이트
            final marker = NMarker(
              id: 'current_location',
              position: newPoint,
              icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
              size: const Size(15, 15),
              anchor: const NPoint(0.5, 0.5),
            );
            _mapController?.addOverlay(marker);

            // 이동 기록 및 속도 계산
            if (_isRecording && !_isPaused) {
              final lastPoint = _currentLocation;

              // 이동 거리 계산, 이상치 필터링 (100m 이상 무시)
              if (lastPoint != null) {
                final distance = Geolocator.distanceBetween(
                  lastPoint.latitude,
                  lastPoint.longitude,
                  newPoint.latitude,
                  newPoint.longitude,
                );
                if (distance >= 0 && distance < 100) {
                  _distance += distance;
                }
              }

              _currentLocation = newPoint;

              // 평균 속도 계산
              final elapsedSec = _stopwatch.elapsed.inSeconds;
              if (_distance > 0 && elapsedSec > 0) {
                _avgSpeed = (_distance / elapsedSec) * 3.6;
              }

              // 최고 속도 업데이트
              if (currentSpeedKmh > _maxSpeed) _maxSpeed = currentSpeedKmh;

              // Offline mode: 경로 그리기
              _addPointToRoute(newPoint);
            }

            setState(() {
              _currentSpeed = currentSpeedKmh;
              _isLoading = false;
            });

            // 카메라 따라가기
            if (_isFollowingUser && _isMapVisible && _mapController != null) {
              final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
                target: newPoint,
                zoom: await _mapController!.getCameraPosition().then((p) => p.zoom),
              );
              _mapController!.updateCamera(cameraUpdate);
            }
          },
          onError: (error) {
            if (_isLoading) {
              _showError('Failed to get location: $error');
            }
          },
        );
  }

  void _addPointToRoute(NLatLng point) {
    if (!mounted) return;
    setState(() {
      var lastChunk = _routeChunks.last;

      // 마지막 청크 좌표도 다음 청크 좌표에 저장하기
      if (lastChunk.length >= _chunkSize) {
        final NLatLng lastPoint = lastChunk.last;
        _routeChunks.add([lastPoint]);
        lastChunk = _routeChunks.last;
      }
      lastChunk.add(point);

      // 경로를 chunk에 저장하기
      if (_mapController != null) {
        final chunkIndex = _routeChunks.length - 1;
        _mapController!.addOverlay(
          NPathOverlay(
            id: 'route_chunk_$chunkIndex',
            coords: lastChunk,
            width: 6,
            color: Colors.blue,
            outlineWidth: 2,
            outlineColor: Colors.white,
          ),
        );
      }
    });
  }

  void _startRecording() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('주행을 기록합니다.')),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    final int newRouteId = await RouteApi.getRouteId(token);
    setState(() {
      _currentRouteId = newRouteId;
    });

    if (_currentRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경로 ID를 가져오지 못했습니다. 다시 시도해주세요.')),
      );
      return;
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

    setState(() {
      _isRecording = true;
      _isPaused = false;

      // Reset values
      _distance = 0.0;
      _avgSpeed = 0.0;
      _elapsedTime = '00:00:00';
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _routeChunks.clear();
      _routeChunks.add([]);

      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _elapsedTime = formatTime(_stopwatch.elapsed.inSeconds);
          });
        }
      });
    });
  }

  void _stopRecordingAndNavigate(BuildContext context) async {
    final token = context.read<AuthProvider>().token;
    if (!_isRecording) return;

    _isMapVisible = true;

    _stopwatch.stop();
    _timer?.cancel();

    final distanceInKm = (_distance / 1000).toStringAsFixed(2);
    final elapsedTime = _elapsedTime;
    final avgSpeed = _avgSpeed.toStringAsFixed(1);

    // --- 스크린샷을 위한 위치 값 구하기 ---
    String? snapshotPath;
    final fullRoute = _routeChunks.expand((chunk) => chunk).toList();

    if (fullRoute.isNotEmpty && _mapController != null) {
      final bounds = NLatLngBounds.from(fullRoute);
      final cameraUpdate = NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(40));
      cameraUpdate.setAnimation(animation: NCameraAnimation.none);

      await _mapController!.updateCamera(cameraUpdate);
    } else {
      final cameraUpdate = NCameraUpdate.withParams(target: _currentLocation);
      cameraUpdate.setAnimation(animation: NCameraAnimation.none);

      await _mapController!.updateCamera(cameraUpdate);
    }

    final imageFile = await _mapController!.takeSnapshot();
    snapshotPath = imageFile.path;
    // --- 스크린샷 로직 끝 ---

    final reportId = await ReportApi.createReport(
      ReportCreate(
        routeId: _currentRouteId!,
        healthTime: timeToIntMinute(_elapsedTime),
        distance: _distance,
        averageSpeed: _avgSpeed,
        highestSpeed: _maxSpeed,
      ),
      token!
    );

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostFormScreen(
        reportId: reportId,
        routeId: _currentRouteId,
        initialDistance: distanceInKm,
        initialTime: elapsedTime,
        initialAvgSpeed: avgSpeed,
        mapImagePath: snapshotPath,
      ),
    ));

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _routeChunks = [[]];

      _stopwatch.reset();
      _distance = 0.0;
      _avgSpeed = 0.0;
      _elapsedTime = '00:00:00';
      _currentSpeed = 0.0;
      _maxSpeed = 0.0;
      _routeChunks.clear();
      _routeChunks.add([]);
    });
  }

  void _togglePause() {
    if (!_isRecording) return;
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _stopwatch.stop();
      } else {
        _stopwatch.start();
      }
    });
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _recenterMap() {
    if (_currentLocation != null && _mapController != null) {
      setState(() {
        _isFollowingUser = true;
      });
      _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: _currentLocation!,
          zoom: 16.5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentLocation == null
          ? const Center(child: Text('위치 정보를 가져올 수 없습니다.'))
          : Stack(
        children: [
          Offstage(
            offstage: !_isMapVisible || !_isMapReady,
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: _currentLocation!,
                  zoom: 16.0,
                ),
                locationButtonEnable: false,
                consumeSymbolTapEvents: false,
                mapType: NMapType.basic,
                buildingHeight: 0.0,
                indoorEnable: false,
                liteModeEnable: true,
                symbolScale: 0.0,
                nightModeEnable: false,
              ),
              onMapReady: (controller) async {
                _mapController = controller;

                if (_currentLocation != null) {
                  // Add the initial location marker when the map is ready
                  final marker = NMarker(
                    id: 'current_location',
                    position: _currentLocation!,
                    icon: NOverlayImage.fromAssetImage('assets/image/circleMarker.png'),
                    size: const Size(15, 15),
                    anchor: const NPoint(0.5, 0.5),
                  );
                  _mapController!.addOverlay(marker);
                }
              },
              onCameraChange:
                  (NCameraUpdateReason reason, bool animated) {
                if (reason == NCameraUpdateReason.gesture &&
                    _isFollowingUser) {
                  setState(() {
                    _isFollowingUser = false;
                  });
                }
              },
            ),
          ),
          if (!_isMapVisible && _isMapReady)
            Container(color: Colors.white),

          // Conditional Overlays
          _isRecording
              ? RecordingOverlay(
            isPaused: _isPaused,
            isMapVisible: _isMapVisible,
            distance: _distance,
            avgSpeed: _avgSpeed,
            elapsedTime: _elapsedTime,
            currentSpeed: _currentSpeed,
            maxSpeed: _maxSpeed,
            onRotateMap: () => _mapController?.updateCamera(
                NCameraUpdate.withParams(bearing: 0)),
            onRecenterMap: _recenterMap,
            onTogglePause: _togglePause,
            onStopRecording: () =>
                _stopRecordingAndNavigate(context),
            onToggleMapVisibility: () {
              setState(() {
                _isMapVisible = !_isMapVisible;
              });
            },
            mapController: _mapController,
          )
              : PreRecordingOverlay(
            onBackPressed: () =>
                Navigator.of(context).pop(),
            onRotateMap: () => _mapController?.updateCamera(
                NCameraUpdate.withParams(bearing: 0)),
            onRecenterMap: _recenterMap,
            onStartRecording: _startRecording,
            mapController: _mapController,
          ),

          // Common UI - Ad Banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                height: 60,
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: Text(
                    'Ad Placeholder',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),
          // Navigation List Modal Handle
          Positioned(
            bottom: 60, // Above the ad banner
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.5, // Adjust as needed
                    maxChildSize: 0.9,
                    minChildSize: 0.2,
                    builder: (context, scrollController) => NavigationListModal(
                      scrollController: scrollController,
                    ),
                  ),
                );
              },
              child: Container(
                height: 30, // Height of the handle
                color: Theme.of(context).colorScheme.surface.withAlpha(80), // Semi-transparent handle
                alignment: Alignment.center,
                child: Icon(Icons.keyboard_arrow_up, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}