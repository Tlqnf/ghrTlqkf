import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:pedal/widgets/ad/banner_ad_widget.dart';
import 'package:provider/provider.dart';
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
        mapProvider.authProvider = authProvider;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final mapProviderReader = context.read<MapProvider>();

    if (mapProvider.isLoading || mapProvider.currentUserLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            Offstage(
              offstage: false,
              child: NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(
                    target: mapProvider.currentUserLocation!,
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
                  mapProvider.mapController = controller;
                },
                onCameraChange: (NCameraUpdateReason reason, bool animated) {
                  if (reason == NCameraUpdateReason.gesture &&
                      mapProvider.isFollowing) {
                    mapProviderReader.isFollowingUser = false;
                  }
                },
              ),
            ),
            // Conditional Overlays
            mapProvider.isRecording || mapProvider.isPaused
                ? const RecordingOverlay()
                : PreRecordingOverlay(
              onBackPressed: () => Navigator.of(context).pop(),
            ),
            // Common UI - Ad Banner
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(child: Center(child: BannerAdWidget())),
            ),
          ],
        ),
      ),
    );
  }
}
