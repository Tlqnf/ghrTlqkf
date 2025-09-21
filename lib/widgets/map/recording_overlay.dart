import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/widgets/map/map_control_button.dart';
import 'package:pedal/widgets/map/no_map_recording_view.dart';
import 'package:pedal/widgets/map/stat_card.dart';

class RecordingOverlay extends StatelessWidget {
  final bool isMapVisible;
  final double distance;
  final double avgSpeed;
  final String elapsedTime;
  final double currentSpeed;
  final double maxSpeed;
  final bool isPaused;
  final VoidCallback onRotateMap;
  final VoidCallback onRecenterMap;
  final VoidCallback onTogglePause;
  final VoidCallback onStopRecording;
  final VoidCallback onToggleMapVisibility;
  final NaverMapController? mapController;

  const RecordingOverlay({
    super.key,
    required this.isMapVisible,
    required this.distance,
    required this.avgSpeed,
    required this.elapsedTime,
    required this.currentSpeed,
    required this.maxSpeed,
    required this.isPaused,
    required this.onRotateMap,
    required this.onRecenterMap,
    required this.onTogglePause,
    required this.onStopRecording,
    required this.onToggleMapVisibility,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // === Top section: Either map stats or no-map view ===
        if (isMapVisible) ...[
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatCard(title: '거리', value: (distance / 1000).toStringAsFixed(2), unit: 'km'),
                StatCard(title: '평균 속력', value: avgSpeed.toStringAsFixed(1), unit: 'km/h'),
                StatCard(title: '시간', value: elapsedTime, unit: ''),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: 16,
            child: Column(
              children: [
                MapControlButton(
                  icon: Icons.explore_outlined,
                  onPressed: onRotateMap,
                ),
                const SizedBox(height: 8),
                MapControlButton(
                  icon: Icons.my_location,
                  onPressed: onRecenterMap,
                ),
              ],
            ),
          ),
        ] else ...[
          Positioned.fill(
            child: NoMapRecordingView(
              currentSpeed: currentSpeed,
              isPaused: isPaused,
              togglePause: onTogglePause,
              distance: distance,
              elapsedTime: elapsedTime,
              avgSpeed: avgSpeed,
              maxSpeed: maxSpeed,
            ),
          ),
        ],

        // === Bottom section: Common controls ===
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause,
                            size: 50),
                        onPressed: onTogglePause,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.stop, size: 50),
                        onPressed: onStopRecording,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                MapControlButton(
                  icon: isMapVisible ? Icons.layers_clear : Icons.layers,
                  onPressed: onToggleMapVisibility,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
