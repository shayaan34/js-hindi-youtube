import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _registerMode = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({bool google = false}) async {
    if (!google && !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final state = context.read<AppState>();
    try {
      if (google) {
        await state.signInWithGoogle();
      } else if (_registerMode) {
        await state.register(_name.text.trim(), _company.text.trim(),
            _email.text.trim(), _password.text);
      } else {
        await state.signIn(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.9),
            radius: 1.4,
            colors: [Color(0xFF2A1305), DVColors.background],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeSlideIn(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandWordmark(fontSize: 30),
                    const SizedBox(height: 8),
                    Text(
                      'Visualize advertising displays before installation',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      glow: true,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _registerMode
                                  ? 'Create your company account'
                                  : 'Welcome back',
                              style: text.headlineSmall,
                            ),
                            const SizedBox(height: 20),
                            if (_registerMode) ...[
                              TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.person_outline)),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Enter your name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _company,
                                decoration: const InputDecoration(
                                    labelText: 'Company name',
                                    prefixIcon: Icon(Icons.business_outlined)),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline)),
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Enter a valid email'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Minimum 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white))
                                  : Text(_registerMode
                                      ? 'Create account'
                                      : 'Sign in'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed:
                                  _busy ? null : () => _submit(google: true),
                              icon: const Icon(Icons.g_mobiledata_rounded,
                                  size: 30, color: DVColors.orange),
                              label: const Text('Continue with Google'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(
                                  () => _registerMode = !_registerMode),
                              child: Text(
                                _registerMode
                                    ? 'Already have an account? Sign in'
                                    : "New here? Create a company account",
                                style: const TextStyle(color: DVColors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
