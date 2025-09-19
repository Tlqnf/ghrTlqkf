import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/widgets/map/map_control_button.dart';
import 'package:pedal/widgets/map/record_button.dart';
import 'package:pedal/widgets/modal/navigation_list_modal.dart';

class PreRecordingOverlay extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onRotateMap;
  final VoidCallback onRecenterMap;
  final VoidCallback onStartRecording;
  final NaverMapController? mapController;

  const PreRecordingOverlay({
    super.key,
    required this.onBackPressed,
    required this.onRotateMap,
    required this.onRecenterMap,
    required this.onStartRecording,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 16,
          child: Column(
            children: [
              MapControlButton(
                icon: Icons.arrow_back,
                onPressed: onBackPressed,
              ),
              const SizedBox(height: 32),
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
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: onStartRecording,
              child: const RecordButton(),
            ),
          ),
        ),
        Positioned(
          // 모달
          left: 0,
          right: 0,
          bottom: 60, // Above the ad banner
          top: 0, // Allow it to go all the way to the top
          child: DraggableScrollableSheet(
            initialChildSize: 80 / (MediaQuery.of(context).size.height - 60),
            minChildSize: 80 / (MediaQuery.of(context).size.height - 60),
            maxChildSize: 600 / (MediaQuery.of(context).size.height - 60),
            builder: (BuildContext context, ScrollController scrollController) {
              return NavigationListModal(scrollController: scrollController);
            },
          ),
        ),
      ],
    );
  }
}
