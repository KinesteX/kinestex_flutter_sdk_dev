import 'generic_web_view.dart';
import 'kinestex_logger.dart';

class KinesteXInitializer {
  bool _isInitialized = false;
  final _logger = KinesteXLogger.instance;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(
      String apiKey, String companyName, String userId) async {
    if (_isInitialized) {
      _logger.info('Already initialized');
      return;
    }

    try {
      _logger.info('Initializing SDK...');
      await GenericWebView.warmup(
        apiKey: apiKey,
        companyName: companyName,
        userId: userId,
      );
      _isInitialized = true;
      _logger.success('SDK initialized successfully');
    } catch (e) {
      _logger.error('Initialization error', e);
    }
  }

  Future<void> dispose() async {
    try {
      await GenericWebView.disposeWarmup();
      _isInitialized = false;
    } catch (e) {
      _logger.error('Dispose error', e);
    }
  }
}
