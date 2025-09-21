import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pedal/screens/main_navigation_screen.dart';

class PostFormScreen extends StatefulWidget {
  final String? initialRouteName;
  final String? initialDistance;
  final String? initialTime;
  final String? initialAvgSpeed;
  final String? mapImagePath;

  const PostFormScreen({
    super.key,
    this.initialRouteName,
    this.initialDistance,
    this.initialTime,
    this.initialAvgSpeed,
    this.mapImagePath,
  });

  @override
State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final List<String> _tags = [];
  bool _isCommunityUploadEnabled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRouteName != null) {
      _routeNameController.text = widget.initialRouteName!;
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _tagController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 3) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        top: false, // Allow content to go under the status bar, but respect bottom safe area
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stack for Map and Floating Button
              Stack(
                children: [
                  widget.mapImagePath != null
                      ? Image.file(
                          File(widget.mapImagePath!),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(child: Text('Map Placeholder')),
                        ),
                  Positioned(
                    top: 40, // Adjust position as needed, considering status bar
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Padding for the rest of the content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('거리', widget.initialDistance ?? '0.00', 'km'),
                        _buildStatItem('평균 속력', widget.initialAvgSpeed ?? '0.0', 'km/h'),
                        _buildStatItem('총 시간', widget.initialTime ?? '0시간 00분', ''),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Route Name Input
                    const Text(
                      '경로 이름 *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _routeNameController,
                      decoration: InputDecoration(
                        hintText: '경로 이름을 입력해주세요.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tags Input
                    const Text(
                      '태그',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagController,
                      onSubmitted: (value) => _addTag(value),
                      decoration: InputDecoration(
                        hintText: '추가할 태그를 입력해주세요. (최대 3개)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _tags
                          .map((tag) => Chip(
                        label: Text('#$tag'),
                        onDeleted: () => _removeTag(tag),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Add Photos
                    const Text(
                      '추가 사진',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('640 x 320px 사이즈'),
                            Text('최대 2장까지 추가 가능'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Community Upload Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '커뮤니티 업로드',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _isCommunityUploadEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isCommunityUploadEnabled = value;
                            });
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isCommunityUploadEnabled)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '게시글 제목',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: '게시글 제목을 입력해주세요.',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                          ),
                          const SizedBox(height: 16,),
                const Text(
                  '게시글 내용',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: '게시글에 올릴 내용을 입력해주세요.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle save action
                          debugPrint('Route Name: ${_routeNameController.text}');
                          debugPrint('Tags: $_tags');
                          debugPrint('Community Upload: $_isCommunityUploadEnabled');

                          Navigator.of(context).pushAndRemoveUntil(
                            // 무조건 수정해야 하는 부분
                            MaterialPageRoute(builder: (context) => const MainNavigationScreen(token: "",)),
                                (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Example color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('저장', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
