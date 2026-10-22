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
empty `countryID`. The API exposes no country-list endpoint (the task brief
defines only `checklogin` and `dashboardrates`; list-style routes probed on
2026-10-22 all resolve to catch-all parameter routes, e.g. `rate/{id}`), so
the app scans a configured list of candidate country IDs
(`AppConfig.fallbackCountryScanIds`) and uses the lowest one that actually
returns records. Candidates are probed in parallel batches of 5 so the
fallback adds ~2s instead of ~6s, while the result stays the first available
country in ascending-ID order. For the provided test account
(`payoutCountryId` empty) this is country **6 (Nigeria)**, which returns NGN,
USD and INR rates.

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
