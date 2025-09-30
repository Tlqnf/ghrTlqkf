import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:pedal/widgets/ad/banner_ad_widget.dart';
import 'package:pedal/widgets/map/button/map_control_button.dart';
import 'package:pedal/widgets/map/button/record_button.dart';
import 'package:pedal/widgets/map/modal/navigation_list_modal.dart';
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
                onPressed: () =>
                    mapProvider.mapController?.updateCamera(NCameraUpdate.withParams(bearing: 0)),
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
          bottom: 100,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('주행을 기록합니다.')),
                );
                await mapProviderReader.startRecording();
              },
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
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(child: BannerAdWidget()),
        ),
      ],
    );
  }
}
