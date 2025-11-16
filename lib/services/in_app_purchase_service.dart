import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pedal/config/api_config.dart';

class InAppPurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  List<ProductDetails> _products = [];

  final String _verifyUrl = '${ApiConfig.baseUrl}/purchase/google/verify';

  InAppPurchase get iap => _iap;
  List<ProductDetails> get products => _products;

  Future<void> init() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('스토어 사용 불가');
      return;
    }

    await _loadProducts();

    _purchaseSubscription = _iap.purchaseStream.listen(
      (purchaseDetailsList) {
        _onPurchaseUpdate(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSubscription.cancel();
      },
      onError: (error) {
        debugPrint('구매 스트림 에러: $error');
      },
    );
  }

  void dispose() {
    _purchaseSubscription.cancel();
  }

  Future<void> _loadProducts() async {
    Set<String> kIds = {dotenv.env["GOOGLE_APP_GROUP_PRODUCT_ID"] ?? ""};
    if (kIds.first.isEmpty) {
      debugPrint('상품 ID가 설정되지 않았습니다.');
      return;
    }
    final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);
    if (response.error != null) {
      debugPrint('상품 조회 에러: ${response.error}');
      return;
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('찾을 수 없는 상품 ID: ${response.notFoundIDs}');
    }
    if (response.productDetails.isEmpty) {
      debugPrint('상품이 없습니다.');
    }
    _products = response.productDetails;
  }

  Future<void> buyProduct(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      debugPrint("구독 구매 진행중...");
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint("구독 구매 오류 발생: ${purchaseDetails.error}");
    } else if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      await _verifyAndCompletePurchase(purchaseDetails);
    }
  }

  Future<void> _verifyAndCompletePurchase(
      PurchaseDetails purchaseDetails) async {
    final token = purchaseDetails.verificationData.serverVerificationData;
    debugPrint('서버 검증 시작 (token=${token.isEmpty ? "EMPTY" : "OK"})');

    if (token.isEmpty) {
      debugPrint('서버 검증 토큰이 없습니다.');
      return;
    }

    try {
      final res = await http.post(
        Uri.parse(_verifyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'package_name': 'com.nucl.pedal',
          'purchase_token': token,
          'product_id': purchaseDetails.productID,
        }),
      );

      final data = jsonDecode(res.body);
      final ackState = data['acknowledgementState'];
      final subState = data['subscriptionState'];
      final didServerAck = data['didServerAck'] == true;

      debugPrint(
          '서버 응답: sub=$subState, ack=$ackState, didServerAck=$didServerAck');

      if (res.statusCode == 200 && subState == 'SUBSCRIPTION_STATE_ACTIVE') {
        debugPrint('구독 활성 상태. 접근 권한 부여.');
      }

      if (purchaseDetails.pendingCompletePurchase) {
        final shouldCompleteOnAndroid = !(Platform.isAndroid &&
            ackState == 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED' &&
            didServerAck);

        if (!Platform.isAndroid || shouldCompleteOnAndroid) {
          await _iap.completePurchase(purchaseDetails);
          debugPrint('completePurchase 호출 완료');
        } else {
          debugPrint('completePurchase 생략 (서버에서 이미 처리)');
        }
      }
    } catch (e) {
      debugPrint('서버 검증 실패: $e');
    }
  }

  void showPurchaseCompleteDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          title: Text("${Intl.message('pay')}$text"),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Intl.message("ok")),
            ),
          ],
        );
      },
    );
  }
}
