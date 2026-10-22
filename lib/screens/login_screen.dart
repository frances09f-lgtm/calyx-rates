import 'dart:async';

import 'package:flutter/material.dart';

import '../api/calyx_api.dart';
import '../models/login_result.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final CalyxApi api;
  const LoginScreen({super.key, required this.api});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _slowNote = false;
  String? _error;
  Timer? _slowTimer;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
      _slowNote = false;
    });
    _slowTimer?.cancel();
    // The pilot sign-in server regularly needs ~35s; tell the user we are
    // still waiting instead of showing a silent spinner.
    _slowTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _busy) setState(() => _slowNote = true);
    });
    try {
      final LoginResult login = await widget.api.login(
        userName: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(api: widget.api, login: login),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Network error. Check your connection.');
    } finally {
      _slowTimer?.cancel();
      if (mounted) {
        setState(() {
          _busy = false;
          _slowNote = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.currency_exchange_rounded,
                      size: 56, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Calyx Rates',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to see your default country rates',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.outline),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _userCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    onSubmitted: (_) => _busy ? null : _signIn(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: TextStyle(color: scheme.onErrorContainer)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign in',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (_busy && _slowNote) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Still waiting - the sign-in server is slow to respond '
                      '(it often needs ~30 seconds).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
