import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:pedal/providers/map_provider.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';
import 'package:pedal/widgets/map/button/map_control_button.dart';
import 'package:pedal/widgets/map/button/record_button.dart';
import 'package:pedal/widgets/map/modal/navigation_list_modal.dart';
import 'package:provider/provider.dart';

class PreRecordingOverlay extends StatelessWidget {
  final VoidCallback onBackPressed;

  const PreRecordingOverlay({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final mapProviderReader = context.read<MapProvider>();

    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 20,
          left: 16,
          child: Column(
            children: [
              // 상단 뒤로가기 버튼
              MapControlButton(
                icon: Icons.arrow_back,
                onPressed: onBackPressed,
              ),
              const SizedBox(height: 32),
              MapControlButton(
                icon: Icons.explore_outlined,
                onPressed: () => mapProvider.mapController?.updateCamera(
                  NCameraUpdate.withParams(bearing: 0),
                ),
              ),
              const SizedBox(height: 8),
              MapControlButton(
                icon: Icons.my_location,
                onPressed: mapProviderReader.recenterMap,
              ),
              const SizedBox(height: 8),
              MapControlButton(
                icon: Icons.route,
                onPressed: () {
                  final parentContext = context;

                  showModalBottomSheet(
                    context: parentContext,
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.7,
                      maxChildSize: 0.7,
                      minChildSize: 0.3,
                      builder: (context, scrollController) =>
                          NavigationListModal(
                            scrollController: scrollController,
                            mapProvider: mapProvider,
                          ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // 하단 기록 시작 버튼
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () async {
                showOverlaySnackBar(context, '주행을 기록합니다.');
                await mapProviderReader.startRecording();
              },
              child: const RecordButton(),
            ),
          ),
        ),
      ],
    );
  }
}
