import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:pedal/screens/post_form_screen.dart';
import 'package:pedal/widgets/ad/banner_ad_widget.dart';
import 'package:pedal/widgets/map/button/map_control_button.dart';
import 'package:pedal/screens/no_map_recording_screen.dart';
import 'package:pedal/widgets/map/card/stat_card.dart';
import 'package:provider/provider.dart';

class RecordingOverlay extends StatelessWidget {
  const RecordingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final mapProviderReader = context.read<MapProvider>();

    return Stack(
      children: [
        // === Top section: Either map stats or no-map view ===
        Consumer<MapProvider>(
          builder: (context, mapProvider, child) {
            if (mapProvider.isMapVisible) {
              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatCard(
                            title: '거리',
                            value: mapProvider.distance.toStringAsFixed(2),
                            unit: 'km',
                          ),
                          const SizedBox(width: 10),
                          StatCard(
                            title: '현재 속력',
                            value: mapProvider.currentSpeed.toStringAsFixed(1),
                            unit: 'km/h',
                          ),
                          const SizedBox(width: 10),
                          StatCard(
                            title: '시간',
                            value: mapProvider.time,
                            unit: '',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 100,
                    left: 16,
                    child: Column(
                      children: [
                        MapControlButton(
                          icon: Icons.explore_outlined,
                          onPressed: () =>
                              mapProvider.mapController?.updateCamera(
                                NCameraUpdate.withParams(bearing: 0),
                              ),
                        ),
                        const SizedBox(height: 8),
                        MapControlButton(
                          icon: Icons.my_location,
                          onPressed: mapProviderReader.recenterMap,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Positioned.fill(
                child: NoMapRecordingView(
                  currentSpeed: mapProvider.currentSpeed,
                  isPaused: mapProvider.isPaused,
                  pauseAndRecording: mapProviderReader.pauseAndRecording,
                  distance: mapProvider.distance,
                  elapsedTime: mapProvider.time,
                  avgSpeed: mapProvider.avgSpeed,
                  maxSpeed: mapProvider.maxSpeed,
                ),
              );
            }
          },
        ),

        // === Bottom section: Common controls ===
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Consumer<MapProvider>(
              builder: (context, mapProvider, child) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              mapProvider.isPaused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              size: 50,
                            ),
                            onPressed: () => mapProviderReader.pauseAndRecording(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.stop, size: 50),
                            onPressed: () async {
                              final navData = await mapProviderReader
                                  .stopRecording();
                              if (navData != null && context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PostFormScreen(
                                      initialDistance:
                                          navData['initialDistance'],
                                      initialTime: navData['initialTime'],
                                      initialAvgSpeed:
                                          navData['initialAvgSpeed'],
                                      initialMaxSpeed:
                                          navData['initialMaxSpeed'],
                                      mapImagePath: navData['mapImagePath'],
                                      routeCoords: navData['routeCoords'],
                                    ),
                                  ),
                                );
                              }
                              if (context.mounted) {
                                mapProviderReader.resetRecording();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  MapControlButton(
                    icon: mapProvider.isMapVisible
                        ? Icons.layers_clear
                        : Icons.layers,
                    onPressed: () => mapProviderReader.mapVisibility(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: Center(child: BannerAdWidget())),
        ),
      ],
    );
  }
}