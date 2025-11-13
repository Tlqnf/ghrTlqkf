import 'package:flutter/material.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/viewmodels/post_form_viewmodel.dart';
import 'package:pedal/widgets/post_form/post_form_actions_section.dart';
import 'package:pedal/widgets/post_form/post_form_community_section.dart';
import 'package:pedal/widgets/post_form/post_form_image_section.dart';
import 'package:pedal/widgets/post_form/post_form_main_section.dart';
import 'package:pedal/widgets/post_form/post_form_stats_section.dart';
import 'package:provider/provider.dart';

class PostFormScreen extends StatefulWidget {
  final int? routeId;
  final double? initialDistance;
  final String? initialTime;
  final double? initialAvgSpeed;
  final double? initialMaxSpeed;
  final String? mapImagePath;
  final List<List<double>>? routeCoords;
  final Post? postData;

  const PostFormScreen({
    super.key,
    required this.routeId,
    this.initialDistance,
    this.initialTime,
    this.initialAvgSpeed,
    this.initialMaxSpeed,
    this.mapImagePath,
    this.routeCoords,
    this.postData,
  });

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  late final PostFormViewModel _viewModel;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = PostFormViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _viewModel.init(
        context,
        routeId: widget.routeId,
        initialDistance: widget.initialDistance,
        initialTime: widget.initialTime,
        initialAvgSpeed: widget.initialAvgSpeed,
        initialMaxSpeed: widget.initialMaxSpeed,
        mapImagePath: widget.mapImagePath,
        routeCoords: widget.routeCoords,
        postData: widget.postData,
      );
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: const Scaffold(
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostFormImageSection(),
                PostFormStatsSection(),
                PostFormMainSection(),
                PostFormCommunitySection(),
                PostFormActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
