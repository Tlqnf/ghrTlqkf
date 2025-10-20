import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/widgets/bar/custom_snackbar.dart'; // New import

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;
  final String token;
  final bool? isEditing;

  const ProfileSetupScreen({
    super.key,
    required this.onSetupComplete,
    required this.token,
    this.isEditing,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  dynamic userInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing != null) {
      _initProfile();
    }
  }

  void _initProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      userInfo = await UserApi.fetchUserProfile(widget.token);
      _usernameController.text = userInfo.username;
      _descriptionController.text = userInfo.profileDescription ?? '';
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, '프로필 정보를 불러오지 못했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (_usernameController.text.isEmpty) {
      showCustomSnackBar(context, '닉네임은 필수 항목입니다.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserApi.updateUserProfile(
        token: widget.token,
        username: _usernameController.text,
        profileDescription: _descriptionController.text,
        profilePicFile: _imageFile,
      );
      if (widget.onSetupComplete != null) {
        widget.onSetupComplete!();
        showCustomSnackBar(context, '정상적으로 프로필이 생성되었습니다.');
      } else {
        showCustomSnackBar(context, "정상적으로 프로필이 수정되었습니다.");
      }

      await Navigator.pushReplacementNamed(context, "/main");
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, "오류 발생: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          '프로필 설정',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        flexibleSpace: Container(color: Theme.of(context).colorScheme.surface),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    _isLoading
                        ? const CircleAvatar(
                      radius: 40,
                      child: CircularProgressIndicator(),
                    )
                        : CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFE0E0E0),
                      backgroundImage: _imageFile != null
                          ? FileImage(File(_imageFile!.path))
                          : (userInfo?.profilePic != null &&
                          userInfo.profilePic!.isNotEmpty
                          ? NetworkImage(userInfo.profilePic!)
                          : null) as ImageProvider?,
                      child: (_imageFile == null &&
                          (userInfo?.profilePic == null ||
                              userInfo.profilePic!.isEmpty))
                          ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '프로필 이미지 선택',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _pickImage,
                          child: const Text(
                            '업로드',
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Text(
                      '닉네임',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
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
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: '닉네임을 입력해주세요.',
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
                const Text(
                  '설명',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '자신을 소개하는 설명 문구를 입력해주세요.',
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
                const Spacer(),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submitProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text('프로필 설정'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}