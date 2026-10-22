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

  /// POST /userlogin/checklogin
  Future<LoginResult> login({
    required String userName,
    required String password,
  }) async {
    final res = await _client.post(
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
    );
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
  Future<CountryRates?> _ratesForCountry(LoginResult login, String countryID) async {
    final res = await _client.post(
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
    );
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

  /// Default-country rates for the dashboard: the login response's
  /// payoutCountryId, or the first country with records when that is empty.
  Future<CountryRates> defaultCountryRates(LoginResult login) async {
    if (login.payoutCountryId.isNotEmpty) {
      final r = await _ratesForCountry(login, login.payoutCountryId);
      if (r != null) return r;
    }
    for (final id in AppConfig.fallbackCountryScanIds) {
      final r = await _ratesForCountry(login, id.toString());
      if (r != null) return r;
    }
    throw const ApiException('No country rates available.');
  }

  void dispose() => _client.close();
}
