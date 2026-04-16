import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class NativeAdWidget extends StatefulWidget {
  final String adUnitId;
  const NativeAdWidget({super.key, required this.adUnitId});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: '',
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.black26,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black,
            backgroundColor: Colors.amber,
            style: NativeTemplateFontStyle.bold,
            size: 16.0),
        primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.bold,
            size: 16.0),
        secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white70,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 14.0),
        tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white54,
            backgroundColor: Colors.transparent,
            style: NativeTemplateFontStyle.normal,
            size: 12.0),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native Ad loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native Ad failed to load: $error');
          ad.dispose();
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    if (_nativeAd != null && _isAdLoaded) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 350, // Standard size for TemplateType.medium
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AdWidget(ad: _nativeAd!),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
