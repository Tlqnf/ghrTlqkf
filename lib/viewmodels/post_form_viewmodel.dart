import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pedal/api/post_api.dart';
import 'package:pedal/api/report_api.dart';
import 'package:pedal/api/route_api.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/post.dart';
import 'package:pedal/models/report.dart';
import 'package:pedal/models/route.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:pedal/screens/main_navigation_screen.dart';
import 'package:pedal/services/admob_service.dart';
import 'package:pedal/utils/time_formatter.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart';
import 'package:provider/provider.dart';

class PostFormViewModel extends ChangeNotifier {
  // Dependencies
  late BuildContext _context;
  late AuthProvider _authProvider;

  // Screen arguments
  int? routeId;
  double? initialDistance;
  String? initialTime;
  double? initialAvgSpeed;
  double? initialMaxSpeed;
  String? mapImagePath;
  List<List<double>>? routeCoords;
  Post? postData;

  // State
  final TextEditingController routeNameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final List<String> tags = [];
  bool isCommunityUploadEnabled = false;

  final ImagePicker _picker = ImagePicker();
  final List<XFile> additionalImages = [];
  final List<String> additionalImageUrls = []; // Server image URLs
  final List<Map<String, dynamic>> additionalImageInfos = [];
  bool isLoading = false;
  bool isEditing = false;

  final PageController pageController = PageController();
  int currentImagePage = 0;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  int get imageCount =>
      (mapImagePath != null ? 1 : 0) +
      additionalImages.length +
      additionalImageUrls.length;

  void init(
    BuildContext context, {
    required int? routeId,
    double? initialDistance,
    String? initialTime,
    double? initialAvgSpeed,
    double? initialMaxSpeed,
    String? mapImagePath,
    List<List<double>>? routeCoords,
    Post? postData,
  }) {
    _context = context;
    _authProvider = Provider.of<AuthProvider>(_context, listen: false);

    this.routeId = routeId;
    this.initialDistance = initialDistance;
    this.initialTime = initialTime;
    this.initialAvgSpeed = initialAvgSpeed;
    this.initialMaxSpeed = initialMaxSpeed;
    this.mapImagePath = mapImagePath;
    this.routeCoords = routeCoords;
    this.postData = postData;

    _loadInterstitialAd();

    if (postData != null) {
      isEditing = true;
      routeNameController.text = postData.routeName;
      titleController.text = postData.title;
      bodyController.text = postData.content;
      tags.addAll(postData.hashTag);
      additionalImageInfos.addAll(postData.images);
      additionalImageUrls.addAll(
        postData.images.map((image) => image["url"].toString()),
      );
      isCommunityUploadEnabled = postData.public;
    } else {
      if (initialDistance != null) {
        isCommunityUploadEnabled = true;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    routeNameController.dispose();
    tagController.dispose();
    titleController.dispose();
    bodyController.dispose();
    pageController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void onPageChanged(int page) {
    currentImagePage = page;
    notifyListeners();
  }

  void toggleCommunityUpload(bool value) {
    isCommunityUploadEnabled = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    if (additionalImages.length + additionalImageUrls.length >= 2) {
      showOverlaySnackBar(_context, '최대 2장의 사진만 추가할 수 있습니다.');
      return;
    }
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (selectedImage != null) {
      additionalImages.add(selectedImage);
      notifyListeners();
    }
  }

  void addTag(String tag) {
    if (tag.isNotEmpty && !tags.contains(tag) && tags.length < 3) {
      tags.add(tag);
      tagController.clear();
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    tags.remove(tag);
    notifyListeners();
  }

  void removeAdditionalImage(int index) {
    additionalImages.removeAt(index);
    notifyListeners();
  }

  void removeAdditionalImageUrl(int index) {
    additionalImageUrls.removeAt(index);
    additionalImageInfos.removeAt(index);
    notifyListeners();
  }

  void _loadInterstitialAd() async {
    final token = _authProvider.token;
    if (token != null) {
      final isSubscribed = await UserApi.getUserSubscription(token);
      if (isSubscribed == true) {
        return;
      }
    }
    final adUnitId = AdMobService.interstitialAdUnitId;
    if (adUnitId == null) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
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
    Navigator.of(_context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> savePost() async {
    if (routeNameController.text.isEmpty) {
      showOverlaySnackBar(_context, '경로 이름은 필수입니다.');
      return;
    }
    if (isCommunityUploadEnabled && titleController.text.isEmpty) {
      showOverlaySnackBar(_context, '커뮤니티에 업로드하려면 게시글 제목이 필요합니다.');
      return;
    }

    _setLoading(true);

    try {
      final token = _authProvider.token;
      if (token == null) {
        showOverlaySnackBar(_context, '인증 정보가 없습니다. 다시 로그인해주세요.');
        _setLoading(false);
        return;
      }

      routeId = await RouteApi.getRouteId(token);

      final List<String> additionalImagePaths = additionalImages
          .map((xfile) => xfile.path)
          .toList();

      await RouteApi.updateRoute(
        UpdateRoute(
          name: routeNameController.text,
          pointsJson: routeCoords?.map((coord) {
            return {"lat": coord[0].toDouble(), "lon": coord[1].toDouble()};
          }).toList(),
        ),
        routeId!,
        token,
      );

      final reportId = await ReportApi.createReport(
        ReportCreate(
          routeId: routeId!,
          healthTime: timeToInt(initialTime!),
          distance: initialDistance,
          averageSpeed: initialAvgSpeed,
          highestSpeed: initialMaxSpeed,
        ),
        _authProvider.token!,
      );

      final post = CreatePost(
        title: isCommunityUploadEnabled
            ? titleController.text
            : routeNameController.text,
        content: isCommunityUploadEnabled ? bodyController.text : '',
        hashTag: tags,
        reportId: reportId,
        public: isCommunityUploadEnabled,
        routeId: routeId,
      );

      final isSuccess = await PostApi.createPost(
        post.toJsonString(),
        mapImagePath,
        additionalImagePaths,
        token,
      );

      if (isSuccess) {
        for (var img in additionalImages) {
          final file = File(img.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        additionalImages.clear();

        showOverlaySnackBar(_context, '성공적으로 생성되었습니다.');
        if (_isAdLoaded && _interstitialAd != null) {
          _interstitialAd!.show();
        } else {
          _navigateToHome();
        }
      } else {
        showOverlaySnackBar(_context, '생성에 실패했습니다.');
      }
    } catch (e) {
      showOverlaySnackBar(_context, '생성 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePost() async {
    if (routeNameController.text.isEmpty) {
      showOverlaySnackBar(_context, '경로 이름은 필수입니다.');
      return;
    }
    if (isCommunityUploadEnabled && titleController.text.isEmpty) {
      showOverlaySnackBar(_context, '커뮤니티에 업로드하려면 게시글 제목이 필요합니다.');
      return;
    }

    _setLoading(true);

    try {
      final token = _authProvider.token;
      if (token == null) {
        showOverlaySnackBar(_context, '인증 정보가 없습니다. 다시 로그인해주세요.');
        _setLoading(false);
        return;
      }
      if (routeId == null) {
        showOverlaySnackBar(_context, '경로 ID가 없습니다.');
        _setLoading(false);
        return;
      }

      final List<String> additionalImagePaths = additionalImages
          .map((xfile) => xfile.path)
          .toList();

      final List<int> imagesToKeepIds = additionalImageInfos
          .where((img) => additionalImageUrls.contains(img["url"]))
          .map((img) => img["id"] as int)
          .toList();

      final post = UpdatePost(
        title: isCommunityUploadEnabled
            ? titleController.text
            : routeNameController.text,
        content: isCommunityUploadEnabled ? bodyController.text : '',
        hashTag: tags,
        public: isCommunityUploadEnabled,
        imagesToKeepIds: imagesToKeepIds,
      );

      await RouteApi.updateRoute(
        UpdateRoute(name: routeNameController.text),
        routeId!,
        token,
      );

      final isSuccess = await PostApi.updatePost(
        post.toJsonString(),
        postData!.id,
        additionalImagePaths,
        token,
      );

      if (isSuccess) {
        for (var img in additionalImages) {
          final file = File(img.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
        additionalImages.clear();

        showOverlaySnackBar(_context, '성공적으로 수정되었습니다.');
        _navigateToHome();
      } else {
        showOverlaySnackBar(_context, '수정에 실패했습니다.');
      }
    } catch (e) {
      showOverlaySnackBar(_context, '저장 중 오류가 발생했습니다: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePost() async {
    final token = _authProvider.token;
    if (token == null || postData == null) return;

    _setLoading(true);
    final response = await PostApi.deletePost(postData!.id, token);
    _setLoading(false);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      showOverlaySnackBar(_context, '성공적으로 삭제되었습니다.');
      _navigateToHome();
    } else {
      try {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = responseBody['detail'] ?? '삭제에 실패했습니다.';
        showOverlaySnackBar(
          _context,
          '오류: ${response.statusCode} - $errorMessage',
        );
      } catch (e) {
        showOverlaySnackBar(_context, '삭제에 실패했습니다.');
      }
    }
  }
}
