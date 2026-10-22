/// App configuration.
class AppConfig {
  static const String apiBase = 'https://currencyexchangesoftware.eu/pilot/api';

  // API tenant identifiers required by the task brief's payloads.
  static const String clientID = '1';
  static const String branchID = '2';

  /// When the login response has an empty payoutCountryId, the task asks for
  /// "first country" rates. The app reads the API's own ordered list from
  /// POST /country/countrylist and uses the first listed country that returns
  /// rate records. These candidate IDs are only a backup, used when the
  /// country-list call itself fails. (For the test account the list's first
  /// entry, Australia, returns no records; the second, Nigeria, does.)
  static const List<int> fallbackCountryScanIds = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
  ];
}
