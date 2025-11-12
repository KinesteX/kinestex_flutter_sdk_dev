class KinesteXCredentials {
  String? _apiKey;
  String? _companyName;
  String? _userId;

  void set(String apiKey, String companyName, String userId) {
    _apiKey = apiKey;
    _companyName = companyName;
    _userId = userId;
  }

  KinesteXCreds get credentials {
    if (_apiKey == null || _companyName == null || _userId == null) {
      throw Exception('SDK: Missing credentials. Call initialize() first.');
    }

    return KinesteXCreds(
      apiKey: _apiKey!,
      companyName: _companyName!,
      userId: _userId!,
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
