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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      title: const Text('약관 동의', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600)),
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
                  builder: (context) => const TermsScreen(type: 'terms'),
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
                  builder: (context) => const TermsScreen(type: 'privacy'),
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
          checkColor: Colors.white,
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
