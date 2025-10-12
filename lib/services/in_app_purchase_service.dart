import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';

class InAppPurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  String _productId = "";

  InAppPurchase get iap => _iap;
  List<ProductDetails> get products => _products;
  String get productId => _productId;

  void loadProducts() async {
    const Set<String> kIds = {};
    final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);
    if (response.notFoundIDs.isEmpty) {
      _products = response.productDetails;
    }
  }

  void buyProduct(ProductDetails product, String productID) {
    _productId = productID;
    debugPrint("선택한 id: $_productId}");
    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void listenToPurchaseUpdated() {
    final purchaseUpdated = _iap.purchaseStream;
    purchaseUpdated.listen((purchaseDetailsList) {
      purchaseDetailsList.forEach((purchaseDetails) async {
        if (purchaseDetails.status == PurchaseStatus.pending) {
          // 구매 진행중
          debugPrint("구독 구매 진행중");
        } else {
          if (purchaseDetails.status == PurchaseStatus.error) {
            // 구매 오류 발생시
            debugPrint("구독 구매 오류 발생");
          } else if (purchaseDetails.status == PurchaseStatus.purchased) {
            // 구매 성공
            if (purchaseDetails.pendingCompletePurchase) {
              await verifyPurchase(_productId, purchaseDetails); // 검증 필요?
              await _iap.completePurchase(purchaseDetails);
              debugPrint("구독 구매 완료");
            }
          }
        }
      });
    });
  }

  Future<bool> verifyPurchase(
      String productId, PurchaseDetails purchaseDetails) async {
    // 플랫폼 확인
    String platform = Platform.isAndroid ? 'google' : 'apple';

    // POST 데이터
    Map<String, dynamic> purchaseData = {
      'platform': platform,
    };

    // 플랫폼에 따라 필요한 데이터를 추가
    if (platform == 'apple') {
      purchaseData['encoded_receipt_data'] =
          purchaseDetails.verificationData.localVerificationData;
    } else if (platform == 'google') {
      purchaseData['product_id'] = productId;
      purchaseData['purchase_token'] = purchaseDetails.purchaseID;
    }

    // 서버 연결 로직 추가
    return true;
  }

  void showPurchaseCompleteDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("${Intl.message('pay')}$text"),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(Intl.message("ok"))
            ),
          ],
        );
      }
    );
  }
}