import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/login_result.dart';
import '../models/rate.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class CalyxApi {
  final http.Client _client;
  CalyxApi({http.Client? client}) : _client = client ?? http.Client();

  /// The pilot login endpoint is slow server-side (measured 2026-10-22:
  /// 35-36s on every call, headers in 0.3s then the body completes ~35s
  /// later), so the login timeout is generous. Rates answer in ~1s.
  static const Duration loginTimeout = Duration(seconds: 60);
  static const Duration ratesTimeout = Duration(seconds: 20);

  /// POST /userlogin/checklogin
  Future<LoginResult> login({
    required String userName,
    required String password,
  }) async {
    http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${AppConfig.apiBase}/userlogin/checklogin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userName': userName,
              'password': password,
              'credentialFlag': '',
              'clientID': AppConfig.clientID,
              'branchID': AppConfig.branchID,
              'otp': '',
              'resendotp': '',
              'captcha': '',
              'latitude': '',
              'longitude': '',
              'deviceId': '',
              'ipAddress': '',
            }),
          )
          .timeout(loginTimeout);
    } on TimeoutException {
      throw const ApiException(
          'The sign-in server did not answer within 60 seconds. '
          'It is often slow - please try again.');
    }
    if (res.statusCode != 200) {
      throw ApiException('Login failed (HTTP ${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['response'] != true) {
      throw ApiException(json['data']?.toString() ?? 'Invalid credentials.');
    }
    return LoginResult.fromJson(json);
  }

  /// POST /rate/dashboardrates for one country. Returns null when the
  /// country has no records (the API answers response:false).
  Future<CountryRates?> _ratesForCountry(
      LoginResult login, String countryID) async {
    final res = await _client
        .post(
          Uri.parse('${AppConfig.apiBase}/rate/dashboardrates'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${login.token}',
          },
          body: jsonEncode({
            'customerID': login.customerID,
            'clientID': login.clientID,
            'branchID': login.branchID,
            'countryID': countryID,
            'fromCurrencyCode': login.currencyID,
            'newAgentBranch': '',
            'newAgentID': '',
            'commentFlag': '',
            'offer_rate_flag': '1',
          }),
        )
        .timeout(ratesTimeout);
    if (res.statusCode != 200) {
      throw ApiException('Rates request failed (HTTP ${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['response'] != true || json['data'] is! List) return null;
    final rates = (json['data'] as List)
        .map((e) => Rate.fromJson(e as Map<String, dynamic>))
        .toList();
    if (rates.isEmpty) return null;
    return CountryRates(countryID: countryID, rates: rates);
  }

  /// Like [_ratesForCountry] but treats any failure as "no records" so one
  /// bad candidate does not abort the first-available-country scan.
  Future<CountryRates?> _tryCountry(LoginResult login, String countryID) async {
    try {
      return await _ratesForCountry(login, countryID);
    } catch (_) {
      return null;
    }
  }

  /// POST /country/countrylist with only clientID + branchID (no token).
  /// Returns the API's own ordered country IDs (71 entries for this tenant:
  /// Australia first, Nigeria second).
  Future<List<String>> _countryIds() async {
    final res = await _client
        .post(
          Uri.parse('${AppConfig.apiBase}/country/countrylist'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'clientID': AppConfig.clientID,
            'branchID': AppConfig.branchID,
          }),
        )
        .timeout(ratesTimeout);
    if (res.statusCode != 200) {
      throw ApiException('Country list failed (HTTP ${res.statusCode}).');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['response'] != true || json['data'] is! List) {
      throw const ApiException('Country list unavailable.');
    }
    return (json['data'] as List)
        .map((e) => (e as Map<String, dynamic>)['countryID']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Default-country rates for the dashboard: the login response's
  /// payoutCountryId, or the first country with records when that is empty.
  ///
  /// "First country" follows the API's own ordering from
  /// POST /country/countrylist: entries are probed in list order (parallel
  /// batches of 5 to stay fast) and the first one that returns rate records
  /// wins. For the provided test account that is Nigeria (the list's second
  /// entry; the first, Australia, returns no records). If the country-list
  /// call itself fails, the configured candidate IDs are used as a backup.
  Future<CountryRates> defaultCountryRates(LoginResult login) async {
    if (login.payoutCountryId.isNotEmpty) {
      final r = await _ratesForCountry(login, login.payoutCountryId);
      if (r != null) return r;
    }
    List<String> ids;
    try {
      ids = await _countryIds();
    } catch (_) {
      ids = AppConfig.fallbackCountryScanIds.map((e) => e.toString()).toList();
    }
    const batchSize = 5;
    for (var i = 0; i < ids.length; i += batchSize) {
      final end = i + batchSize > ids.length ? ids.length : i + batchSize;
      final results = await Future.wait(
        ids.sublist(i, end).map((id) => _tryCountry(login, id)),
      );
      for (final r in results) {
        if (r != null) return r;
      }
    }
    throw const ApiException('No country rates available.');
  }

  void dispose() => _client.close();
}
