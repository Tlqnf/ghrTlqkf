import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedal/config/api_config.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/services/socket_service.dart';
import 'package:pedal/utils/time_formatter.dart';
import 'package:pedal/widgets/map/modal/navigation_list_modal.dart';
import 'package:pedal/widgets/map/overlay/pre_recording_overlay.dart';
import 'package:pedal/widgets/map/overlay/recording_overlay.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map and Location State
  NLatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  NaverMapController? _mapController;
  List<List<NLatLng>> _routeChunks = [[]];
  final int _chunkSize = 25; // 경로 생성 조작
  bool _isFollowingUser = true;
  bool _isMapVisible = true;
  bool _isMapReady = false; // Variable to control map loading

  // Socket State
  SocketService? _socketService;
  StreamSubscription<dynamic>? _socketStreamSubscription;
  bool _isSocketConnected = false;

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

  @override
  void initState() {
    super.initState();
    _initializeLocationStream();

    // Delay map loading to prevent transition animation conflicts
    Future.delayed(const Duration(milliseconds: 400), () {
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
    _socketStreamSubscription?.cancel();
    _socketService?.disconnect();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _initializeSocket(String token) {
    _socketStreamSubscription?.cancel();
    String socketUrl = '${ApiConfig.socketUrl}/ws/record-route?token=$token';
    _socketService = SocketService(url: socketUrl);
    _socketStreamSubscription = _socketService!.stream.listen((data) {
      if (mounted && _isSocketConnected) {
        try {
          debugPrint('Socket received data: $data');
          final decoded = jsonDecode(data);
          if (decoded is Map &&
              decoded.containsKey('lat') &&
              decoded.containsKey('lon')) {
            final calibratedPoint = NLatLng(decoded['lat'], decoded['lon']);
            if (_isRecording && !_isPaused) {
              _addPointToRoute(calibratedPoint);
            }
          }
        } catch (e) {
          debugPrint("Error processing socket message: $e");
        }
      }
    }, onError: (error) {
      debugPrint("Socket stream error: $error");
      setState(() {
        _isSocketConnected = false;
      });
    });
  }

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

    // 첫 화면 로딩 속도 증가 -> 마지막 기록 GPS
    Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
    if (lastKnownPosition != null && mounted) {
      setState(() {
        _currentLocation =
            NLatLng(lastKnownPosition.latitude, lastKnownPosition.longitude);
        _isLoading = false;
      });
    }

    // 백그라운드에서 최신 위치 정보 수집
    Position? currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = NLatLng(currentPosition.latitude, currentPosition.longitude);
    });

    _startLocationStream();
  }

  void _startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
    );

    _positionStreamSubscription =
      Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) async {
          if (!mounted) return;

          final newPoint = NLatLng(position.latitude, position.longitude);
          final currentSpeedKmh = position.speed * 3.6;

          // Update marker on the map
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
            _currentLocation = newPoint;
            if (lastPoint != null) {
              _distance += Geolocator.distanceBetween(
                lastPoint.latitude,
                lastPoint.longitude,
                newPoint.latitude,
                newPoint.longitude,
              );
            }

            final elapsedSec = _stopwatch.elapsed.inSeconds;
            if (_distance > 0 && elapsedSec > 0) {
              _avgSpeed = (_distance / elapsedSec) * 3.6;
            }

            if (currentSpeedKmh > _maxSpeed) _maxSpeed = currentSpeedKmh;

            if (_isSocketConnected) {
              final locationData = {
                'lat': position.latitude,
                'lon': position.longitude,
              };
              final message = jsonEncode(locationData);
              _socketService!.sendMessage(message);
              debugPrint('Socket sent data: $message');
            } else {
              // Offline mode: draw route directly from GPS
              _addPointToRoute(newPoint);
            }
          }

          setState(() {
            _currentSpeed = currentSpeedKmh;
            _isLoading = false;
          });

          // Update camera position if following user
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
            width: 4,
            color: Colors.blue,
            outlineWidth: 1,
            outlineColor: Colors.white,
          ),
        );
      }
    });
  }

  void _startRecording() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      debugPrint("Authentication token not found. Cannot connect to socket.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
        );
      }
      return;
    }

    setState(() {
      _isSocketConnected = false; // Reset before attempting connection
    });

    try {
      _initializeSocket(token); // Initialize socket service and listener
      // Assume connected if _initializeSocket doesn't throw immediately.
      // The onError callback in _initializeSocket will set _isSocketConnected to false if connection fails later.
      setState(() {
        _isSocketConnected = true;
      });
      debugPrint('Attempting socket connection...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('소켓을 통해 주행을 기록합니다. (연결 시도 중)')),
        );
      }
    } catch (e) {
      debugPrint('Socket initialization failed: $e. Falling back to offline mode.');
      setState(() {
        _isSocketConnected = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('소켓 연결 실패. 오프라인 모드로 주행을 기록합니다.')),
        );
      }
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
    if (!_isRecording) return;
    _socketService?.disconnect();
    debugPrint('Socket disconnected.');

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

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PostFormScreen(
        initialDistance: distanceInKm,
        initialTime: elapsedTime,
        initialAvgSpeed: avgSpeed,
        mapImagePath: snapshotPath,
        reportId: 1,
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