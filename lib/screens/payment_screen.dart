import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:pedal/services/in_app_purchase_service.dart';
import 'package:pedal/screens/main_navigation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final InAppPurchaseService iapService = InAppPurchaseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePayments();
  }

  @override
  void dispose() {
    iapService.dispose();
    super.dispose();
  }

  Future<void> _initializePayments() async {
    await iapService.init();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFEEAEE), // Light pink from top
              Colors.white,     // Fading to white
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 30),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const Icon(
                          Icons.do_not_disturb_on,
                          color: Color(0xFFE53935), // A strong red
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '광고 없이\n더 쾌적한 라이딩 환경으로\n업그레이드해보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildBenefitItem(
                          title: '주행 집중 및 흐름 유지',
                          subtitle: '기록 진행/저장 중 광고가 발생하지 않아요.',
                        ),
                        const SizedBox(height: 24),
                        _buildBenefitItem(
                          title: '빠른 속도 & 안정성',
                          subtitle: '더 빠르고, 부드러운 경험을 할 수 있어요.',
                        ),
                        const SizedBox(height: 24),
                        _buildBenefitItem(
                          title: '클린 디자인',
                          subtitle: '깔끔한 화면, 라이딩을 더 돋보이게 해줘요.',
                        ),
                        const SizedBox(height: 24),
                        _buildBenefitItem(
                          title: '커뮤니티 기여',
                          subtitle: '페달 커뮤니티에 더 좋은 문화를 만들어줘요.',
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      '월 2,500원에 체험해보세요.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (iapService.products.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('결제 상품을 불러오지 못했습니다. 잠시 후 다시 시도해주세요.')),
                                  );
                                  return;
                                }
                                try {
                                  final productId = dotenv.env["GOOGLE_APP_GROUP_PRODUCT_ID"] ?? "";
                                  ProductDetails product =
                                      iapService.products.firstWhere(
                                          (p) => p.id == productId);
                                  iapService.buyProduct(product);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('구매 처리 중 오류가 발생했습니다: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9524E),
                          disabledBackgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                '프리미엄 모드로 주행하기',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

  Widget _buildBenefitItem({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom shape for the icon
        ClipPath(
          clipper: _BenefitIconClipper(),
          child: Container(
            width: 40,
            height: 50,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4), // To align text better with icon
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom clipper for the benefit icon shape
class _BenefitIconClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height * 0.75);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
