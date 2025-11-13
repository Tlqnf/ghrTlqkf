import 'package:flutter/material.dart';
import 'package:pedal/viewmodels/post_form_viewmodel.dart';
import 'package:provider/provider.dart';

class PostFormStatsSection extends StatelessWidget {
  const PostFormStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostFormViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  '거리',
                  viewModel.postData?.distance.toStringAsFixed(2) ??
                      viewModel.initialDistance!.toStringAsFixed(2),
                  'km'),
              _buildStatItem(
                  '평균 속력',
                  viewModel.postData?.speed.toStringAsFixed(1) ??
                      viewModel.initialAvgSpeed!.toStringAsFixed(1),
                  'km/h'),
              _buildStatItem('총 시간',
                  viewModel.postData?.time ?? viewModel.initialTime ?? '00:00:00', ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.red)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ],
        ),
      ],
    );
  }
}
