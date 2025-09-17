import 'package:flutter/material.dart';

class PostFormScreen extends StatefulWidget {
  final String? initialRouteName;
  final String? initialDistance;
  final String? initialTime;

  const PostFormScreen({
    super.key,
    this.initialRouteName,
    this.initialDistance,
    this.initialTime,
  });

  @override
State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          '게시글 작성',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Placeholder
            Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: Text('Map Placeholder')),
            ),
            const SizedBox(height: 16),

            // Stats Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('거리', widget.initialDistance ?? '0.00', 'km'),
                _buildStatItem('평균 속력', '19.92', 'km/h'), // Placeholder value
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
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action
                  debugPrint('Route Name: ${_routeNameController.text}');
                  debugPrint('Tags: $_tags');
                  debugPrint('Community Upload: $_isCommunityUploadEnabled');
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
