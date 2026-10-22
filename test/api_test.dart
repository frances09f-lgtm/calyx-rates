import 'dart:convert';

import 'package:calyx_rates/api/calyx_api.dart';
import 'package:calyx_rates/models/login_result.dart';
import 'package:calyx_rates/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
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

  test('defaultCountryRates follows the countrylist order, not ID order',
      () async {
    // Live behavior verified 2026-10-23: countrylist returns Australia (13)
    // first and Nigeria (6) second; 13 returns "No Records Found", 6 has
    // rates, so the app lands on Nigeria by list order - not by ID luck.
    final api = CalyxApi(
      client: MockClient((req) async {
        if (req.url.path.endsWith('/country/countrylist')) {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body.keys, unorderedEquals(['clientID', 'branchID']));
          expect(req.headers.containsKey('Authorization'), isFalse);
          return http.Response(
              jsonEncode({
                'response': true,
                'data': [
                  {'countryID': '13', 'countryName': 'Australia'},
                  {'countryID': '6', 'countryName': 'Nigeria'},
                ]
              }),
              200);
        }
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

  test('countrylist order wins even when a later ID is lower', () async {
    final api = CalyxApi(
      client: MockClient((req) async {
        if (req.url.path.endsWith('/country/countrylist')) {
          return http.Response(
              jsonEncode({
                'response': true,
                'data': [
                  {'countryID': '9'},
                  {'countryID': '3'},
                ]
              }),
              200);
        }
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
            jsonEncode({
              'response': true,
              'data': [
                {'currencyCode': 'X', 'countryID': body['countryID']}
              ]
            }),
            200);
      }),
    );
    final r = await api.defaultCountryRates(_login());
    expect(r.countryID, '9');
  });

  test('falls back to candidate IDs when the countrylist call fails',
      () async {
    final api = CalyxApi(
      client: MockClient((req) async {
        if (req.url.path.endsWith('/country/countrylist')) {
          return http.Response('server error', 500);
        }
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

  testWidgets('avatar shows capital letter when no image path', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ProfileAvatar(imagePath: null, initial: 'P'),
      ),
    ));
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('avatar keeps letter when image fails to load', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ProfileAvatar(
            imagePath: 'https://invalid.invalid/nope.png', initial: 'P'),
      ),
    ));
    await t.pump();
    expect(find.text('P'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('empty name yields ? initial, no crash', () {
    final login = LoginResult(
      customerID: '', fullName: '', userName: '', clientID: '', branchID: '',
      currencyID: '', currencyCode: '', currencySign: '', payoutCountryId: '',
      profileImagePath: null, token: '',
    );
    expect(login.initial, '?');
  });

  test('fallback probe skips a failing country and keeps list order',
      () async {
    final api = CalyxApi(
      client: MockClient((req) async {
        if (req.url.path.endsWith('/country/countrylist')) {
          return http.Response(
              jsonEncode({
                'response': true,
                'data': [
                  {'countryID': '1'},
                  {'countryID': '2'},
                  {'countryID': '3'},
                  {'countryID': '6'},
                ]
              }),
              200);
        }
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final id = body['countryID'];
        if (id == '3') return http.Response('server error', 500);
        if (id == '2' || id == '6') {
          return http.Response(
              jsonEncode({
                'response': true,
                'data': [
                  {'currencyCode': 'X', 'countryID': id}
                ]
              }),
              200);
        }
        return http.Response(
            jsonEncode({'response': false, 'data': 'No Records Found.'}), 200);
      }),
    );
    final r = await api.defaultCountryRates(_login());
    expect(r.countryID, '2');
  });

  test('regression: live dashboardrates response maps verbatim, zeros kept',
      () async {
    // Verbatim live response (2026-10-22) for countryID=6, offer_rate_flag 1:
    // the pilot server has a real rate only for NGN; USD/INR are 0.0000
    // server-side. The app must display exactly what the API returns.
    const raw = {
      'response': true,
      'responseCode': '00',
      'data': [
        {
          'pty': '6', 'preferred_flag': '0', 'preferred_customer': '0',
          'pc': '0', 'currencyCode': 'NGN', 'currencyName': 'Nigerian naira',
          'minAmount': '0', 'maxAmount': '100', 'rate': '11.2300',
          'imageName': 'NGN.png', 'countryFlag': 'images/flags/ngn.png',
          'ID': '96439277', 'countryID': '6', 'currencyID': '43',
        },
        {
          'pty': '6', 'preferred_flag': '0', 'preferred_customer': '0',
          'pc': '0', 'currencyCode': 'USD',
          'currencyName': 'United States Dollars', 'minAmount': '0',
          'maxAmount': '100', 'rate': '0.0000', 'imageName': 'USD.png',
          'countryFlag': 'images/flags/ngn.png', 'ID': '96439278',
          'countryID': '6', 'currencyID': '7',
        },
        {
          'pty': '6', 'preferred_flag': '0', 'preferred_customer': '0',
          'pc': '0', 'currencyCode': 'INR', 'currencyName': 'Indian Rupee',
          'minAmount': '0', 'maxAmount': '100', 'rate': '0.0000',
          'imageName': 'INR.png', 'countryFlag': 'images/flags/ngn.png',
          'ID': '96439279', 'countryID': '6', 'currencyID': '23',
        },
      ],
    };
    final api = CalyxApi(
      client: MockClient((req) async => http.Response(jsonEncode(raw), 200)),
    );
    final r = await api.defaultCountryRates(_login(payoutCountryId: '6'));
    expect(r.countryID, '6');
    expect(r.rates.map((e) => e.currencyCode), ['NGN', 'USD', 'INR']);
    expect(r.rates.map((e) => e.rate), ['11.2300', '0.0000', '0.0000']);
    expect(r.rates.map((e) => e.minAmount), ['0', '0', '0']);
    expect(r.rates.map((e) => e.maxAmount), ['100', '100', '100']);
    expect(r.rates[1].currencyName, 'United States Dollars');
  });
}
