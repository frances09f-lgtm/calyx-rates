# Calyx Rates

Flutter task submission for Calyx Solutions (24-hour exercise).

## What it does

1. **Login** against `POST /pilot/api/userlogin/checklogin` (test account
   prefilled, see below).
2. **Profile circle** on the dashboard: shows `customer_profileimage` when the
   login response has one, otherwise the first letter of the user's name in
   capitals inside a colored circle.
3. **Default country rates** on the dashboard from
   `POST /pilot/api/rate/dashboardrates` (JWT bearer token from login):
   - uses the login response's `payoutCountryId` when it is set;
   - when `payoutCountryId` is empty, shows the first country's rates.

## Notes on the "first country" fallback

This API exposes no country-list endpoint, and `dashboardrates` rejects an
empty `countryID`. The app therefore scans a configured list of candidate
country IDs (`AppConfig.fallbackCountryScanIds`) in ascending order and uses
the first one that returns records. For the provided test account
(`payoutCountryId` empty) this is country **6 (Nigeria)**, which returns NGN,
USD and INR rates.

## Test credentials

`lib/config.dart` contains the HR-provided test account from the task brief
(`pratikraut.calyx@gmail.com`), prefilled into the login form for easy
evaluation. It is flagged in the file header; a production build would not
ship credentials.

## Stack

Flutter 3.47.6 (stable), Material 3, `http` only. Structure:
`lib/api` (API client), `lib/models`, `lib/screens`, `lib/widgets`,
`lib/config.dart`. Unit tests in `test/api_test.dart` cover the login field
mapping, the avatar-initial rule and both rate-country branches.

## Build

CI (`.github/workflows/build-apk.yml`) runs analyze + tests and builds the
release APK (debug-signed, standard for a task build). Download from
[Releases](../../releases).
