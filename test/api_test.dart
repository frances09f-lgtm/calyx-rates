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

  test('fallback scan skips a failing country and keeps ascending order',
      () async {
    final api = CalyxApi(
      client: MockClient((req) async {
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
}
