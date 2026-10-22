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

  /// Default-country rates for the dashboard: the login response's
  /// payoutCountryId, or the first country with records when that is empty.
  ///
  /// The API exposes no country-list endpoint (the task brief defines only
  /// checklogin and dashboardrates; list-style routes probed 2026-10-22 all
  /// resolve to catch-all parameter routes). "First country" is therefore
  /// the lowest candidate ID that actually returns rate records. Candidates
  /// are probed in parallel batches to keep the fallback fast (~2s instead
  /// of ~6s sequential) while preserving ascending-ID order.
  Future<CountryRates> defaultCountryRates(LoginResult login) async {
    if (login.payoutCountryId.isNotEmpty) {
      final r = await _ratesForCountry(login, login.payoutCountryId);
      if (r != null) return r;
    }
    const batchSize = 5;
    final ids = AppConfig.fallbackCountryScanIds;
    for (var i = 0; i < ids.length; i += batchSize) {
      final end =
          i + batchSize > ids.length ? ids.length : i + batchSize;
      final results = await Future.wait(
        ids.sublist(i, end).map((id) => _tryCountry(login, id.toString())),
      );
      for (final r in results) {
        if (r != null) return r;
      }
    }
    throw const ApiException('No country rates available.');
  }

  void dispose() => _client.close();
}
