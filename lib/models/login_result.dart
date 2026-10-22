class LoginResult {
  final String customerID;
  final String fullName;
  final String userName;
  final String clientID;
  final String branchID;
  final String currencyID;
  final String currencyCode;
  final String currencySign;
  final String payoutCountryId;
  final String? profileImagePath;
  final String token;

  const LoginResult({
    required this.customerID,
    required this.fullName,
    required this.userName,
    required this.clientID,
    required this.branchID,
    required this.currencyID,
    required this.currencyCode,
    required this.currencySign,
    required this.payoutCountryId,
    required this.profileImagePath,
    required this.token,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return LoginResult(
      customerID: data['customerID'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      clientID: data['clientID'] as String? ?? '',
      branchID: data['branchID'] as String? ?? '',
      currencyID: data['currencyID'] as String? ?? '',
      currencyCode: data['currencyCode'] as String? ?? '',
      currencySign: data['currencySign'] as String? ?? '',
      payoutCountryId: data['payoutCountryId'] as String? ?? '',
      profileImagePath: data['customer_profileimage'] as String?,
      token: data['token'] as String? ?? '',
    );
  }

  /// First letter of the display name in capitals, for the avatar fallback.
  String get initial =>
      fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase();
}
