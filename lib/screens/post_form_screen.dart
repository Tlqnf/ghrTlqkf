import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/route.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pedal/services/admob_service.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';


class PostFormScreen extends StatefulWidget {
  final int? reportId;
  final int? routeId;
  final String? initialDistance;
  final String? initialTime;
  final String? initialAvgSpeed;
  final String? mapImagePath;
  final List<List<double>>? routeCoords;
  final Post? postData;

  const PostFormScreen({
    super.key,
    this.reportId,
    this.routeId,
    this.initialDistance,
    this.initialTime,
    this.initialAvgSpeed,
    this.mapImagePath,
    this.routeCoords,
    this.postData,
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
  final List<String> _additionalImageUrls = []; // 서버 이미지 URL
  final List<Map<String, dynamic>> _additionalImageInfos = [];
  bool _isLoading = false;
  bool _isEditing = false;

  final PageController _pageController = PageController();
  int _currentImagePage = 0;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();

    if (widget.postData != null) {
      // Editing an existing post
      _isEditing = true;
      _routeNameController.text = widget.postData!.routeName;
      _titleController.text = widget.postData!.title;
      _bodyController.text = widget.postData!.content;
      _tags.addAll(widget.postData!.hashTag);
      _additionalImageInfos.addAll(widget.postData!.images);
      _additionalImageUrls.addAll(
          widget.postData!.images.map((image) => image["url"])
      );
      _isCommunityUploadEnabled = widget.postData!.public;
    } else {
      // Creating a new post
      // If coming from a record, default to community upload
      if (widget.initialDistance != null) {
        _isCommunityUploadEnabled = true;
      }
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
    if (_additionalImages.length + _additionalImageUrls.length >= 2) {
      showCustomSnackBar(context, '최대 2장의 사진만 추가할 수 있습니다.');
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

  void _loadInterstitialAd() {
    final adUnitId = AdMobService.interstitialAdUnitId;
    if (adUnitId == null) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _navigateToHome();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              debugPrint('Failed to show ad: $error');
              _navigateToHome();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _savePost() async {
    if (_routeNameController.text.isEmpty) {
      showCustomSnackBar(context, '경로 이름은 필수입니다.');
      return;
    }
    if (_isCommunityUploadEnabled && _titleController.text.isEmpty) {
      showCustomSnackBar(context, '커뮤니티에 업로드하려면 게시글 제목이 필요합니다.');
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
          showCustomSnackBar(context, '인증 정보가 없습니다. 다시 로그인해주세요.');
        }
        setState(() => _isLoading = false);
        return;
      } else if (widget.routeId == null) {
        showCustomSnackBar(context, '경로 ID가 없습니다.');
        return;
      }

      final String? mapImagePath = widget.mapImagePath;
      final List<String> additionalImagePaths =
      _additionalImages.map((xfile) => xfile.path).toList();

      await RouteApi.updateRoute(
        UpdateRoute(
          name: _routeNameController.text,
          pointsJson: widget.routeCoords?.map((coord) {
            return {
              "lat": coord[0].toDouble(),
              "lon": coord[1].toDouble(),
            };
          }).toList(),
        ),
        widget.routeId!,
        token,
      );

      final postData = CreatePost(
        title: _isCommunityUploadEnabled
            ? _titleController.text
            : _routeNameController.text,
        content: _isCommunityUploadEnabled ? _bodyController.text : '',
        hashTag: _tags,
        reportId: widget.reportId,
        public: _isCommunityUploadEnabled,
        routeId: widget.routeId,
      );

      final isSuccess = await PostApi.createPost(
        postData.toJsonString(),
        mapImagePath,
        additionalImagePaths,
        token,
      );

      if (isSuccess) {
        for (var img in _additionalImages) {
          final file = File(img.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _additionalImages.clear();

        if (mounted) {
          showCustomSnackBar(context, '성공적으로 생성되었습니다.');
          if (_isAdLoaded && _interstitialAd != null) {
            _interstitialAd!.show();
          } else {
            _navigateToHome();
          }
        }
      } else {
        if (mounted) {
          showCustomSnackBar(context, '생성에 실패했습니다.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, '생성 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePost() async {
    if (_routeNameController.text.isEmpty) {
      showCustomSnackBar(context, '경로 이름은 필수입니다.');
      return;
    }
    if (_isCommunityUploadEnabled && _titleController.text.isEmpty) {
      showCustomSnackBar(context, '커뮤니티에 업로드하려면 게시글 제목이 필요합니다.');
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
          showCustomSnackBar(context, '인증 정보가 없습니다. 다시 로그인해주세요.');
        }
        setState(() => _isLoading = false);
        return;
      } else if (widget.routeId == null) {
        showCustomSnackBar(context, '경로 ID가 없습니다.');
        return;
      }

      // 새로 추가된 이미지 경로
      final List<String> additionalImagePaths =
      _additionalImages.map((xfile) => xfile.path).toList();

      // 유지할 기존 이미지들의 ID
      final List<int> imagesToKeepIds = _additionalImageInfos
          .where((img) => _additionalImageUrls.contains(img["url"]))
          .map((img) => img["id"] as int)
          .toList();

      final postData = UpdatePost(
        title: _isCommunityUploadEnabled
            ? _titleController.text
            : _routeNameController.text,
        content: _isCommunityUploadEnabled ? _bodyController.text : '',
        hashTag: _tags,
        public: _isCommunityUploadEnabled,
        imagesToKeepIds: imagesToKeepIds
      );

      await RouteApi.updateRoute(
        UpdateRoute(
          name: _routeNameController.text,
        ),
        widget.routeId!,
        token,
      );

      final isSuccess = await PostApi.updatePost(
        postData.toJsonString(),
        widget.postData!.id,
        additionalImagePaths,
        token, // 유지할 이미지 id
      );

      if (isSuccess) {
        for (var img in _additionalImages) {
          final file = File(img.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _additionalImages.clear();

        if (mounted) {
          showCustomSnackBar(context, '성공적으로 수정되었습니다.');
          _navigateToHome();
        }
      } else {
        if (mounted) {
          showCustomSnackBar(context, '수정에 실패했습니다.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, '저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePost() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null || widget.postData == null) return;
    final response = await PostApi.deletePost(widget.postData!.id, token);

    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      showCustomSnackBar(context, '성공적으로 삭제되었습니다.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      final errorMessage = responseBody['detail'] ?? '삭제에 실패했습니다.';
      showCustomSnackBar(context, '오류: ${response.statusCode} - $errorMessage');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageCount =
        (widget.mapImagePath != null ? 1 : 0) + _additionalImages.length + _additionalImageUrls.length;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map + Image Stack
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
                            widget.mapImagePath!.startsWith('http')
                                ? Image.network(
                              widget.mapImagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                                : Image.file(
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
                          ..._additionalImageUrls.map((url) => Image.network(
                            url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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

              // Rest of the form (stats, route name, tags, photos, community switch)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('거리', widget.postData?.distance.toStringAsFixed(2) ?? widget.initialDistance ?? '0.00', 'km'),
                        _buildStatItem('평균 속력', widget.postData?.speed.toStringAsFixed(1) ?? widget.initialAvgSpeed ?? '0.0', 'km/h'),
                        _buildStatItem('총 시간', widget.postData?.time ?? widget.initialTime ?? '00:00:00', ''),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Route Name
                    Row(
                      children: [
                        const Text(
                          '경로 이름',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4,),
                        const Text(
                          "*",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _routeNameController,
                      decoration: InputDecoration(
                        hintText: '경로 이름을 입력해주세요.',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey, // Focus 되어도 회색 그대로
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tags
                    const Text('태그', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagController,
                      onSubmitted: (value) => _addTag(value),
                      decoration: InputDecoration(
                        hintText: '추가할 태그를 입력해주세요. (최대 3개)',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey, // Focus 되어도 회색 그대로
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _tags.map((tag) => Chip(
                        label: Text('#$tag'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.grey,
                          ),
                        ),
                        onDeleted: () => _removeTag(tag),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Additional Photos
                    const Text('추가 사진', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _additionalImages.length + _additionalImageUrls.length + (_additionalImages.length + _additionalImageUrls.length < 2 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _additionalImages.length + _additionalImageUrls.length) {
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
                                    const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 30),
                                    const SizedBox(height: 8),
                                    Text('사진 추가 (${_additionalImages.length + _additionalImageUrls.length}/2)',
                                        style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (index < _additionalImages.length) {
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
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            final urlIndex = index - _additionalImages.length;
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      _additionalImageUrls[urlIndex],
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
                                          _additionalImageUrls.removeAt(urlIndex);
                                          _additionalImageInfos.removeAt(urlIndex);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('상단에서 추가된 사진을 드래그로 확인 가능', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 24,),
                    // Community Upload
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('커뮤니티 업로드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Switch(
                          value: _isCommunityUploadEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isCommunityUploadEnabled = value;
                            });
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isCommunityUploadEnabled)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '게시글 제목',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4,),
                              const Text(
                                "*",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: '게시글 제목을 입력해주세요.',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey, // Focus 되어도 회색 그대로
                                  width: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              const Text(
                                '게시글 내용',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4,),
                              const Text(
                                "*",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              )
                            ],
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
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey, // Focus 되어도 회색 그대로
                                  width: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),

                    // Buttons
                    _isEditing
                        ? _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _deletePost,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
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
                                    child: CircularProgressIndicator(color: Colors.red, strokeWidth: 3),
                                  )
                                      : const Text('삭제', style: TextStyle(fontSize: 18)),
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _updatePost,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
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
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                      : const Text('수정', style: TextStyle(fontSize: 18)),
                                ),
                            ],
                            )
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
          ],
        ),
      ],
    );
  }
}