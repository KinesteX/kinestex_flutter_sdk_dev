class KinesteXCredentials {
  String? _apiKey;
  String? _companyName;
  String? _userId;

  void set(String apiKey, String companyName, String userId) {
    _apiKey = apiKey;
    _companyName = companyName;
    _userId = userId;
  }

  KinesteXCreds resolve(String? apiKey, String? companyName, String? userId) {
    final resolvedApiKey = apiKey ?? _apiKey;
    final resolvedCompanyName = companyName ?? _companyName;
    final resolvedUserId = userId ?? _userId;

    if ([resolvedApiKey, resolvedCompanyName, resolvedUserId].contains(null)) {
      throw Exception('SDK: Missing credentials. Call initialize() first.');
    }

    return KinesteXCreds(
      apiKey: resolvedApiKey!,
      companyName: resolvedCompanyName!,
      userId: resolvedUserId!,
    );
  }
}

class KinesteXCreds {
  final String apiKey;
  final String companyName;
  final String userId;

  KinesteXCreds({
    required this.apiKey,
    required this.companyName,
    required this.userId,
  });
}
