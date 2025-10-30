import 'package:posthog_flutter/posthog_flutter.dart';
import 'generic_web_view.dart';
import 'kinestex_logger.dart';

class KinesteXInitializer {
  bool _isInitialized = false;
  final _logger = KinesteXLogger.instance;

  bool get isInitialized => _isInitialized;
  Posthog? _posthog;

  Future<void> initialize(
      String apiKey, String companyName, String userId) async {
    if (_isInitialized) {
      _logger.info('Already initialized');
      return;
    }

    try {
      _logger.info('Initializing SDK...');
      await GenericWebView.warmup();
      await _initPosthog(apiKey, companyName, userId);
      _isInitialized = true;
      _logger.success('SDK initialized successfully');
    } catch (e) {
      _logger.error('Initialization error', e);
    }
  }

  Future<void> _initPosthog(
    String apiKey,
    String companyName,
    String userId,
  ) async {
    try {
      final config =
          PostHogConfig('phc_5nMm5TFaJUGBdNMyPy66sNnWVjMq8y2smZjCC0ykDTR')
            ..host = 'https://us.i.posthog.com';

      await Posthog().setup(config);
      _posthog = Posthog();
      await _posthog?.identify(userId: userId, userProperties: {
        'company': companyName,
      });
      await _posthog?.capture(
        eventName: 'member_registered',
        properties: {'company': companyName, 'user_id': userId},
      );
      _logger.success('Member added!');
    } catch (e) {
      _logger.error('PostHog tracking failed', e);
    }
  }
}
