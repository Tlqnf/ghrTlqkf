import 'package:flutter/material.dart';
import 'package:pedal/screens/terms_screen.dart';

class TermsOfServiceModal extends StatefulWidget {
  final VoidCallback onAgreed;

  const TermsOfServiceModal({super.key, required this.onAgreed});

  @override
  State<TermsOfServiceModal> createState() => _TermsOfServiceModalState();
}

class _TermsOfServiceModalState extends State<TermsOfServiceModal> {
  bool _agreeAll = false;
  bool _termsOfService = false;
  bool _privacyPolicy = false;
  bool _marketing = false;

  void _updateAgreeAll() {
    if (_termsOfService && _privacyPolicy && _marketing) {
      _agreeAll = true;
    } else if (!_termsOfService || !_privacyPolicy || !_marketing) {
      _agreeAll = false;
    }
    setState(() {});
  }

  bool get _areRequiredTermsAgreed => _termsOfService && _privacyPolicy;

  // Placeholder content for terms
  static const String _termsOfServiceContent = """
서비스 이용약관 내용입니다.
제1조 (목적)
...
""";
  static const String _privacyPolicyContent = """
개인정보 처리방침 내용입니다.
제1조 (개인정보의 처리 목적)
...
""";

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
      title: const Text('약관 동의'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAgreementRow(
            label: '전체 동의',
            value: _agreeAll,
            onChanged: (value) {
              setState(() {
                _agreeAll = value ?? false;
                _termsOfService = _agreeAll;
                _privacyPolicy = _agreeAll;
                _marketing = _agreeAll;
              });
            },
            isBold: true,
          ),
          const Divider(),
          _buildAgreementRow(
            label: '[필수] 서비스 이용약관',
            value: _termsOfService,
            onChanged: (value) {
              setState(() {
                _termsOfService = value ?? false;
                _updateAgreeAll();
              });
            },
            onView: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsScreen( // Navigate to TermsScreen
                    title: '서비스 이용약관',
                    content: _termsOfServiceContent,
                  ),
                ),
              );
            },
          ),
          _buildAgreementRow(
            label: '[필수] 개인정보 처리방침',
            value: _privacyPolicy,
            onChanged: (value) {
              setState(() {
                _privacyPolicy = value ?? false;
                _updateAgreeAll();
              });
            },
            onView: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsScreen( // Navigate to TermsScreen
                    title: '개인정보 처리방침',
                    content: _privacyPolicyContent,
                  ),
                ),
              );
            },
          ),
          _buildAgreementRow(
            label: '[선택] 마케팅 정보 수신 동의',
            value: _marketing,
            onChanged: (value) {
              setState(() {
                _marketing = value ?? false;
                _updateAgreeAll();
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _areRequiredTermsAgreed
              ? () {
                  Navigator.of(context).pop();
                  widget.onAgreed();
                }
              : null,
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildAgreementRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    VoidCallback? onView,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ),
        if (onView != null)
          TextButton(
            onPressed: onView,
            child: const Text('보기'),
          ),
      ],
    );
  }
}

void showTermsOfServiceModal(BuildContext context, {required VoidCallback onAgreed}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return TermsOfServiceModal(onAgreed: onAgreed);
    },
  );
}
