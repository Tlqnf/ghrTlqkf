import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:provider/provider.dart';
import 'package:pedal/widgets/map/modal/navigation_list_modal.dart';
import 'package:pedal/widgets/map/overlay/pre_recording_overlay.dart';
import 'package:pedal/widgets/map/overlay/recording_overlay.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final authProvider = context.read<AuthProvider>();
        final mapProvider = MapProvider();
        mapProvider.update(authProvider);
        return mapProvider;
      },
      child: const MapScreenView(),
    );
  }
}

class MapScreenView extends StatefulWidget {
  const MapScreenView({super.key});

  @override
  State<MapScreenView> createState() => _MapScreenViewState();
}

class _MapScreenViewState extends State<MapScreenView> {
  BannerAd? _bannerAd;
  late final mapProvider = context.watch<MapProvider>(); // 값 표시
  late final mapProviderReader = context.read<MapProvider>(); // 이벤트

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: mapProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : mapProvider.currentLocation == null
              ? const Center(child: Text('위치 정보를 가져올 수 없습니다.'))
              : Stack(
                  children: [
                    Offstage(
                      offstage:
                          !mapProvider.isMapVisible || !mapProvider.isMapReady,
                      child: NaverMap(
                        options: NaverMapViewOptions(
                          initialCameraPosition: NCameraPosition(
                            target: mapProvider.currentLocation!,
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
                          mapProvider.setMapController(controller);
                        },
                        onCameraChange:
                            (NCameraUpdateReason reason, bool animated) {
                          if (reason == NCameraUpdateReason.gesture &&
                              mapProvider.isFollowingUser) {
                            mapProviderReader.setIsFollowingUser(false);
                          }
                        },
                      ),
                    ),
                    if (!mapProvider.isMapVisible && mapProvider.isMapReady)
                      Container(color: Colors.white),

                    // Conditional Overlays
                    mapProvider.isRecording
                        ? const RecordingOverlay()
                        : PreRecordingOverlay(
                            onBackPressed: () => Navigator.of(context).pop(),
                          ),

                    // Common UI - Ad Banner
                    if (_bannerAd != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            height: 60,
                            child: AdWidget(
                              ad: _bannerAd!
                            ),
                          ),
                        ),
                      ),

                    // Navigation List Modal Handle
                    Positioned(
                      bottom: 60,
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
                              initialChildSize: 0.5,
                              maxChildSize: 0.9,
                              minChildSize: 0.2,
                              builder: (context, scrollController) =>
                                  NavigationListModal(
                                scrollController: scrollController,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 50.0,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
