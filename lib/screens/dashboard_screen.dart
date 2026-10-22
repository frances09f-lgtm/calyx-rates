import 'package:flutter/material.dart';

import '../api/calyx_api.dart';
import '../config.dart';
import '../models/login_result.dart';
import '../models/rate.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/rate_tile.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final CalyxApi api;
  final LoginResult login;

  const DashboardScreen({super.key, required this.api, required this.login});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CountryRates? _countryRates;
  String? _error;
  bool _loading = true;

  bool get _usedFallback => widget.login.payoutCountryId.isEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.api.defaultCountryRates(widget.login);
      if (mounted) setState(() => _countryRates = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Network error. Pull down to retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get _flagUrl {
    final p = _countryRates?.flagPath;
    if (p == null || p.isEmpty) return null;
    final origin = Uri.parse(AppConfig.apiBase).origin;
    return '$origin/${p.startsWith('/') ? p.substring(1) : p}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final login = widget.login;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ProfileAvatar(
              imagePath: login.profileImagePath,
              initial: login.initial,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome back,',
                      style: TextStyle(fontSize: 12)),
                  Text(
                    login.fullName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => LoginScreen(api: widget.api)),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                if (_flagUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      _flagUrl!,
                      width: 34,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    _usedFallback
                        ? 'Rates for the first available country'
                        : 'Rates for your default country',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (_usedFallback) ...[
              const SizedBox(height: 4),
              Text(
                'No default country on your profile, showing the first country with rates.',
                style: TextStyle(color: scheme.outline, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48, color: scheme.outline),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                        onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else
              ..._countryRates!.rates.map(
                (r) => RateTile(rate: r, fromCurrencyCode: login.currencyCode),
              ),
          ],
        ),
      ),
    );
  }
}
