import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';

class PostFormScreen extends StatefulWidget {
  final int? postId;
  final int? reportId;
  final String? initialDistance;
  final String? initialTime;
  final String? initialAvgSpeed;
  final String? mapImagePath;
  final String? routeName;
  final List<String>? tagList;
  final String? title;
  final String? content;
  final List<String>? imgUrls;

  const PostFormScreen({
    super.key,
    this.postId,
    this.reportId,
    this.initialDistance,
    this.initialTime,
    this.initialAvgSpeed,
    this.mapImagePath,
    this.routeName,
    this.tagList,
    this.title,
    this.content,
    this.imgUrls,
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

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _additionalImages = [];
  bool _isLoading = false;
  bool _isEditing = false;

  final PageController _pageController = PageController();
  int _currentImagePage = 0;

  @override
  void initState() {
    super.initState();
    _routeNameController.text = widget.routeName ?? widget.routeName ?? '';
    _titleController.text = widget.title ?? '';
    _bodyController.text = widget.content ?? '';

    if (widget.tagList != null) {
      _tags.addAll(widget.tagList!);
    }

    if (widget.routeName != null) {
      _isEditing = true;
    }

    // If coming from a record, default to community upload
    if (widget.initialDistance != null) {
      _isCommunityUploadEnabled = true;
    }
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _tagController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_additionalImages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최대 2장의 사진만 추가할 수 있습니다.')),
      );
      return;
    }
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _additionalImages.add(selectedImage);
      });
    }
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

  Future<void> _savePost() async {
    if (_routeNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('경로 이름은 필수입니다.')),
      );
      return;
    }
    if (_isCommunityUploadEnabled && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('커뮤니티에 업로드하려면 게시글 제목이 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final double? distance = double.tryParse(widget.initialDistance ?? '');
      final double? avgSpeed = double.tryParse(widget.initialAvgSpeed ?? '');
      List<String>? format = widget.initialTime?.split(":");
      final double time = double.parse(
          (int.parse(format![0]) * 3600 + int.parse(format[1]) * 60 + int.parse(format[2])) as String
      );

      final postData = CreatePost(
        title: _isCommunityUploadEnabled
            ? _titleController.text
            : _routeNameController.text,
        content: _isCommunityUploadEnabled ? _bodyController.text : '',
        hashTag: _tags,
        reportId: widget.reportId,
        public: _isCommunityUploadEnabled,
        distance: distance,
        speed: avgSpeed,
        time: time,
      );

      final List<String> imagePaths = [];
      if (widget.mapImagePath != null) {
        imagePaths.add(widget.mapImagePath!);
      }
      imagePaths.addAll(_additionalImages.map((xfile) => xfile.path));

      final response = await PostApiService.createPost(
        postData.toJsonString(),
        imagePaths,
        token,
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성공적으로 저장되었습니다.')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = responseBody['detail'] ?? '저장에 실패했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: ${response.statusCode} - $errorMessage')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveRoute() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;
    await RouteApiService.updateRoute(
      _routeNameController.text,
      _tags,
      token,
      1
    );
  }

  Future<void> _updatePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || widget.postId == null) return;
    final postData = UpdatePost(
      postId: widget.postId ?? -1,
      title: _titleController.text,
      content: _bodyController.text,
    );

    final response = await PostApiService.updatePost(postData, token);

    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성공적으로 저장되었습니다.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMessage = responseBody['detail'] ?? '수정에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: ${response.statusCode} - $errorMessage')),
      );
    }
  }

  Future<void> _deletePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null || widget.postId == null) return;
    final response = await PostApiService.deletePost(widget.postId!, token);

    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성공적으로 저장되었습니다.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMessage = responseBody['detail'] ?? '수정에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: ${response.statusCode} - $errorMessage')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageCount =
        (widget.mapImagePath != null ? 1 : 0) + _additionalImages.length;

    return Scaffold(
      body: SafeArea(
        top: false, // Allow content to go under the status bar, but respect bottom safe area
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stack for Map and Floating Button
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SafeArea(
                    child: SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) {
                          setState(() {
                            _currentImagePage = page;
                          });
                        },
                        children: [
                          if (widget.mapImagePath != null)
                            Image.file(
                              File(widget.mapImagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          else
                            Container(
                              color: Colors.grey[300],
                              child: const Center(child: Text('Map Placeholder')),
                            ),
                          ..._additionalImages.map((image) => Image.file(
                                File(image.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              )),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40, // Adjust position as needed, considering status bar
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        iconSize: 20.0,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                  if (imageCount > 1)
                    Positioned(
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          imageCount,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImagePage == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
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
                        _buildStatItem(
                            '거리', widget.initialDistance ?? '0.00', 'km'),
                        _buildStatItem(
                            '평균 속력', widget.initialAvgSpeed ?? '0.0', 'km/h'),
                        _buildStatItem(
                            '총 시간', widget.initialTime ?? '0시간 00분', ''),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Route Name Input
                    const Text(
                      '경로 이름 *',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _additionalImages.length +
                            (_additionalImages.length < 2 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _additionalImages.length) {
                            return GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 200,
                                height: 100,
                                margin: const EdgeInsets.only(right: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined,
                                        color: Colors.grey, size: 30),
                                    const SizedBox(height: 8),
                                    Text(
                                        '사진 추가 (${_additionalImages.length}/2)',
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(_additionalImages[index].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _additionalImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '상단에서 추가된 사진을 드래그로 확인 가능',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    // Community Upload Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '커뮤니티 업로드',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                          const SizedBox(
                            height: 16,
                          ),
                          const Text(
                            '게시글 내용',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                    _isEditing
                        ? Row(
                            children: [
                              // 삭제
                              ElevatedButton(
                                onPressed: _isLoading ? null : _deletePost,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red, // Example color
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.red,
                                    strokeWidth: 3,
                                  ),
                                )
                                    : const Text('삭제', style: TextStyle(fontSize: 18)),
                              ),
                              const Spacer(),
                              // 수정
                              ElevatedButton(
                                onPressed: _isLoading ? null : _updatePost,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Example color
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 70),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBackgroundColor: Colors.grey[400],
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                    : const Text('수정', style: TextStyle(fontSize: 18)),
                              ),
                            ],
                    )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () {
                                // 경로로 저장
                                _saveRoute();

                                // 게시글로 저장
                                _savePost();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue, // Example color
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                disabledBackgroundColor: Colors.grey[400],
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                                  : const Text('저장', style: TextStyle(fontSize: 18)),
                            ),
                          )
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
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
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