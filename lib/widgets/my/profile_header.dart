import 'package:flutter/material.dart';
import 'package:pedal/api/user_api.dart';
import 'package:pedal/models/user.dart';
import 'package:pedal/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileHeader extends StatefulWidget {
  final String token;
  final VoidCallback? onRemoveAdsTap; // New parameter

  const ProfileHeader({
    super.key,
    required this.token,
    this.onRemoveAdsTap, // Initialize new parameter
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  User? _user;
  bool _isLoading = true;
  String? _error;
  bool _isProfileSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _loadProfileStatus();
  }

  Future<void> _loadProfileStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isSetupComplete = prefs.getBool('profile_setup_complete') ?? false;

    if (isSetupComplete) {
      setState(() {
        _isProfileSetupComplete = true;
        _isLoading = false;
      });
    } else {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw Exception('Token not found');
      }
      final user = await UserApi.fetchUserProfile(token);
      setState(() {
        _user = user;
      });
    } catch (e, s) {
      debugPrint('Error fetching user profile: $e');
      debugPrint('Stack trace: $s');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_isProfileSetupComplete)
            const Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/image/not_profile.png'),
                ),
                SizedBox(width: 16),
                Text(
                  '사용자',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            )
          else
            Row(
              children: [
                _isLoading
                    ? const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: CircularProgressIndicator(),
                      )
                    : _user!.profilePic != null && _user!.profilePic!.isNotEmpty
                    ? CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: _user!.profilePic != null
                            ? ClipOval(
                                child: Image.network(
                                  _user!.profilePic!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.person, size: 30),
                      )
                    : const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage(
                          'assets/image/not_profile.png',
                        ),
                      ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _isLoading
                        ? const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            _user?.username ?? 'Guest',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    _isLoading
                        ? const Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            _user?.email ?? 'example@gmail.com',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                    const SizedBox(height: 4),
                    _isLoading
                        ? const Text(
                            'Loading...',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          )
                        : Text(
                            _user?.profileDescription ?? 'No description',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                    if (_error != null)
                      Text(
                        'Error: $_error',
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          const Spacer(),
          OutlinedButton(
            onPressed: widget.onRemoveAdsTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              side: const BorderSide(color: Colors.transparent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '광고 제거',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }
}
