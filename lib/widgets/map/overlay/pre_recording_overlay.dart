import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:pedal/widgets/map/button/map_control_button.dart';
import 'package:provider/provider.dart';

class PreRecordingOverlay extends StatelessWidget {
  final VoidCallback onBackPressed;

  const PreRecordingOverlay({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final mapProviderReader = context.read<MapProvider>();

    return Stack(
      children: [
        // 상단 뒤로가기 버튼
        Positioned(
          top: 50,
          left: 16,
          child: MapControlButton(
            icon: Icons.arrow_back,
            onPressed: onBackPressed,
          ),
        ),

        // 우측 맵 컨트롤 버튼
        Positioned(
          top: 50,
          right: 16,
          child: Column(
            children: [
              MapControlButton(
                icon: Icons.rotate_left,
                onPressed: () => mapProvider.mapController?.updateCamera(NCameraUpdate.withParams(bearing: 0)),
              ),
              const SizedBox(height: 8),
              MapControlButton(
                icon: Icons.my_location,
                onPressed: mapProviderReader.recenterMap,
              ),
            ],
          ),
        ),

        // 하단 기록 시작 버튼
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('주행을 기록합니다.')),
                );
                await mapProviderReader.startRecording();
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
                backgroundColor: Colors.red,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
