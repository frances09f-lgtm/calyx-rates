import 'dart:convert';

import 'package:calyx_rates/api/calyx_api.dart';
import 'package:calyx_rates/models/login_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

LoginResult _login({String payoutCountryId = '', String? image}) => LoginResult(
      customerID: 'c1',
      fullName: 'Pratik Raut',
      userName: 'p@example.com',
      clientID: '1',
      branchID: '2',
      currencyID: '22',
      currencyCode: 'GBP',
      currencySign: '£',
      payoutCountryId: payoutCountryId,
      profileImagePath: image,
      token: 't',
    );

void main() {
  test('initial is first letter in capitals', () {
    expect(_login().initial, 'P');
    expect(LoginResult.fromJson(const {
      'data': {'fullName': ''}
    }).initial, '?');
  });

  test('defaultCountryRates uses payoutCountryId when present', () async {
    final api = CalyxApi(
      client: MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['countryID'], '6');
        return http.Response(
            jsonEncode({
              'response': true,
              'data': [
                {
                  'currencyCode': 'NGN',
                  'currencyName': 'Nigerian naira',
                  'rate': '1.5',
                  'minAmount': '0',
                  'maxAmount': '100',
                  'countryFlag': 'images/flags/ngn.png',
                  'countryID': '6',
                }
              ]
            }),
            200);
      }),
    );
    final r = await api.defaultCountryRates(_login(payoutCountryId: '6'));
    expect(r.countryID, '6');
    expect(r.rates.single.currencyCode, 'NGN');
  });

  test('defaultCountryRates falls back to first country with records', () async {
    final api = CalyxApi(
      client: MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if (body['countryID'] == '6') {
          return http.Response(
              jsonEncode({
                'response': true,
                'data': [
                  {'currencyCode': 'NGN', 'countryID': '6'}
                ]
              }),
              200);
        }
        return http.Response(
            jsonEncode({'response': false, 'data': 'No Records Found.'}), 200);
      }),
    );
    final r = await api.defaultCountryRates(_login());
    expect(r.countryID, '6');
  });

  test('login maps response fields', () async {
    final api = CalyxApi(
      client: MockClient((req) async => http.Response(
          jsonEncode({
            'response': true,
            'data': {
              'customerID': 'x=',
              'fullName': 'Pratik Raut',
              'payoutCountryId': '',
              'customer_profileimage': null,
              'token': 'jwt',
            }
          }),
          200)),
    );
    final r = await api.login(userName: 'u', password: 'p');
    expect(r.fullName, 'Pratik Raut');
    expect(r.payoutCountryId, isEmpty);
    expect(r.profileImagePath, isNull);
  });
}
