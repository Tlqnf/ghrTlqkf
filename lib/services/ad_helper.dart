// import 'dart:io';
//
// import 'package:flutter/cupertino.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class AdHelper {
//
//   static String get bannerAdUnitId {
//     if (Platform.isAndroid) {
//       return 'ca-app-pub-3940256099942544/6300978111';
//     } else if (Platform.isIOS) {
//       return 'ca-app-pub-3940256099942544/2934735716';
//     } else {
//       throw UnsupportedError('Unsupported platform');
//     }
//   }
//
//   static String get interstitialAdUnitId {
//     if (Platform.isAndroid) {
//       return "ca-app-pub-3940256099942544/1033173712";
//     } else if (Platform.isIOS) {
//       return "ca-app-pub-3940256099942544/4411468910";
//     } else {
//       throw UnsupportedError("Unsupported platform");
//     }
//   }
//
//   static final BannerAdListener bannerAdListener = BannerAdListener(
//     onAdLoaded:  (ad) => debugPrint("Ad Loaded"),
//     onAdFailedToLoad: (ad, error) {
//       ad.dispose();
//       debugPrint('ad fail to load: $error');
//     },
//     onAdOpened: (ad) => debugPrint("Ad opened"),
//     onAdClosed: (ad) => debugPrint("Ad closed")
//   );
// }