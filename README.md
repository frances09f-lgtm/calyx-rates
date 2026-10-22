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
   - when `payoutCountryId` is empty, shows the first country's rates in
     the order of `POST /pilot/api/country/countrylist`.

## Notes on the "first country" fallback

`dashboardrates` rejects an empty `countryID`, so the fallback needs the
API's country ordering. That comes from `POST /pilot/api/country/countrylist`
(only `clientID` + `branchID`, no token), which returns the tenant's
countries in the API's own order. The app walks that list in order
(parallel batches of 5 to stay fast) and uses the first country that
returns rate records. For the provided test account (`payoutCountryId`
empty) the list's first entry, **Australia (countryID 13)**, returns "No
Records Found", so the app shows the second, **Nigeria (countryID 6)**,
with its NGN, USD and INR rates - by the API's ordering, not by scanning
guessed IDs. If the country-list call itself fails, a small configured
candidate list (`AppConfig.fallbackCountryScanIds`) is used as a backup.

## Assumptions (not explicitly defined in the task)

- **Empty `payoutCountryId`:** the app shows rates for the first available
  country. The API exposes no country-list endpoint (list-style routes
  resolve to catch-all parameter routes), so the app probes candidate
  country IDs in ascending order (parallel batches of 5) and uses the
  lowest one that returns rate records. For the provided test account this
  is Nigeria (countryID 6, NGN/USD/INR rates).
- **Selected country returns no data:** if `payoutCountryId` is set but its
  rate request returns no records, the app applies the same
  first-available-country fallback. If no country returns records at all,
  the dashboard shows a clear "no rates available" state with a retry
  button instead of failing silently.

## Test credentials

No credentials are stored in the app. The login form starts empty; sign in
with the test account supplied in the Calyx task brief (v1.0.0/v1.0.1
prefilled it for convenience; v1.0.2 removes stored credentials per the
submission checklist).

## Stack

Flutter 3.47.6 (stable), Material 3, `http` only. Structure:
`lib/api` (API client), `lib/models`, `lib/screens`, `lib/widgets`,
`lib/config.dart`. Unit tests in `test/api_test.dart` cover the login field
mapping, the avatar-initial rule and both rate-country branches.

## Changes in v1.0.3

- Dashboard heading is now "Exchange Rates", with a short subtitle when the
  first-available-country fallback is in use.
- Rate tiles: long currency names (e.g. "United States Dollars") wrap
  cleanly within the tile; API values unchanged.

## Changes in v1.0.2

- Removed the stored/prefilled test credentials (submission checklist:
  no hardcoded credentials). Login form starts empty; the brief's test
  account still works when typed in.
- Added widget tests for the avatar fallback (missing and broken image
  both show the capital letter).
- Sign-in responsiveness around the slow pilot server (the login endpoint
  itself takes ~35s to answer, measured repeatedly on 2026-10-22 with plain
  HTTP calls; the rates endpoint answers in ~1s):
  - the fallback country scan now runs in parallel batches (~2s, was ~6s);
  - login and rates calls have explicit timeouts (60s / 20s) instead of
    waiting forever, with a clear error message;
  - the login screen shows a "server is slow, still waiting" note after 8s
    instead of a silent spinner.

## Build

CI (`.github/workflows/build-apk.yml`) runs analyze + tests and builds the
release APK (debug-signed, standard for a task build). Download from
[Releases](../../releases).
