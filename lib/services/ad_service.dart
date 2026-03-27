import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  // Google's official test Rewarded Ad ID. Stable and always works.
  static const String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool get isAdLoaded => _isAdLoaded;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded Ad loaded.');
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded Ad failed to load: $error');
          _isAdLoaded = false;
          // Attempt to reload after a delay
          Future.delayed(const Duration(minutes: 1), () => _loadRewardedAd());
        },
      ),
    );
  }

  Future<void> showRewardedAd({required Function onUserEarnedReward}) async {
    if (_rewardedAd == null) {
      debugPrint('Warning: Attempted to show ad before it was loaded.');
      // Proceed anyway if it's a test environment or show an error
      // In this app, we'll just execute the reward if it fails to load for better UX during dev.
      onUserEarnedReward();
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdLoaded = false;
        _loadRewardedAd(); // Load the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdLoaded = false;
        _loadRewardedAd();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      onUserEarnedReward();
    });
    
    _rewardedAd = null;
  }
}
