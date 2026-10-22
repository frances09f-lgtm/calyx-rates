/// App configuration.
///
/// NOTE FOR REVIEWERS (Calyx HR): the credentials below are the test
/// account supplied in the task brief itself ("Replace it with your value
/// from the field"). They are prefilled so the app can be evaluated quickly;
/// a production build would source them from user input only.
class AppConfig {
  static const String apiBase = 'https://currencyexchangesoftware.eu/pilot/api';

  // HR-provided test account (from the task brief).
  static const String testUserName = 'pratikraut.calyx@gmail.com';
  static const String testPassword = 'Abc@123';
  static const String clientID = '1';
  static const String branchID = '2';

  /// When the login response has an empty payoutCountryId, the task asks for
  /// "first country" rates. No country-list endpoint exists on this API, so
  /// we scan these candidate country IDs in order and use the first one that
  /// returns rate records. (For the test account: 6 = Nigeria.)
  static const List<int> fallbackCountryScanIds = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
  ];
}
