import 'package:flutter/material.dart';
import 'package:pedal/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title1': '페달에 오신 것을 환영합니다!',
      'title2': '여러분의 라이딩 기록을 공유해보세요',
      'highlight1': '페달',
      'highlight2': '라이딩 기록을 공유',
      'image': 'assets/on_boarding/notice1.png',
    },
    {
      'title1': '페달과 함께',
      'title2': '당신의 라이딩을 기록해보세요',
      'highlight1': '페달',
      'highlight2': '기록',
      'image': 'assets/on_boarding/notice2.png',
    },
    {
      'title1': '페달이 기록한 나의',
      'title2': '라이딩을 한눈에 확인해보세요',
      'highlight1': '페달',
      'highlight2': '한눈에 확인',
      'image': 'assets/on_boarding/notice3.png',
    },
    {
      'title1': '페달과 함께 매일의',
      'title2': '라이딩 습관을 이어가보세요',
      'highlight1': '페달',
      'highlight2': '라이딩 습관',
      'image': 'assets/on_boarding/notice4.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Logo
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Image.asset(
                'assets/Logo.png',
                width: 60,
                height: 60,
              ),
            ),
            const SizedBox(height: 16),

            // 2. Expanded PageView for Text and Image
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Text
                      _buildText(page),

                      // Image
                      Image.asset(
                        page['image']!,
                        width: MediaQuery.of(context).size.width * 0.66,
                      ),
                    ],
                  );
                },
              ),
            ),

            // 3. Fixed Indicator
            _buildIndicator(),
            const SizedBox(height: 10), // Add some space

            // 4. Fixed Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _completeOnboarding, // Corrected this
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE74C3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '바로 시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(Map<String, String> page) {
    List<TextSpan> spans = [];

    // Process title1
    String title1 = page['title1']!;
    String highlight1 = page['highlight1']!;
    int highlight1Index = title1.indexOf(highlight1);

    if (highlight1Index != -1) {
      if (highlight1Index > 0) {
        spans.add(TextSpan(
          text: title1.substring(0, highlight1Index),
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ));
      }
      spans.add(TextSpan(
        text: highlight1,
        style: const TextStyle(
          color: Color(0xFFE74C3C),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ));
      if (highlight1Index + highlight1.length < title1.length) {
        spans.add(TextSpan(
          text: title1.substring(highlight1Index + highlight1.length),
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: title1,
        style: const TextStyle(color: Colors.black, fontSize: 20),
      ));
    }

    spans.add(const TextSpan(text: '\n')); // New line

    // Process title2
    String title2 = page['title2']!;
    String highlight2 = page['highlight2']!;
    int highlight2Index = title2.indexOf(highlight2);

    if (highlight2Index != -1) {
      if (highlight2Index > 0) {
        spans.add(TextSpan(
          text: title2.substring(0, highlight2Index),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ));
      }
      spans.add(TextSpan(
        text: highlight2,
        style: const TextStyle(
          color: Color(0xFFE74C3C),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ));
      if (highlight2Index + highlight2.length < title2.length) {
        spans.add(TextSpan(
          text: title2.substring(highlight2Index + highlight2.length),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ));
      }
    } else {
      spans.add(TextSpan(
        text: title2,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 10 : 8,
          height: _currentPage == index ? 10 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFFE74C3C)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

