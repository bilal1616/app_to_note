// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _showPass = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _showSnack(String message, {IconData icon = Icons.error_outline}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          backgroundColor: theme.colorScheme.surface.withOpacity(.95),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, color: Color.fromARGB(255, 179, 17, 5), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'TAMAM',
            textColor: const Color.fromARGB(255, 179, 17, 5),
            onPressed: () {},
          ),
        ),
      );
  }

  bool _isValidEmail(String v) =>
      RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(v);

  Future<void> _submit() async {
    final name = _fullName.text.trim();
    final mail = _email.text.trim();
    final pass = _pass.text;

    if (name.isEmpty || mail.isEmpty || pass.isEmpty) {
      _showSnack('Lütfen tüm alanları doldurun.');
      return;
    }
    if (!_isValidEmail(mail)) {
      _showSnack('Geçerli bir e-mail adresi girin.');
      return;
    }
    if (pass.length < 6) {
      _showSnack('Şifre en az 6 karakter olmalı.');
      return;
    }

    final err = await context.read<AuthCubit>().register(
      mail,
      pass,
      fullName: name,
    );

    if (!mounted) return;

    if (err != null && err.trim().isNotEmpty) {
      _showSnack(err, icon: Icons.error_outline);
    } else {
      _showSnack(
        'Onay maili gönderildi. Lütfen e-postanızı kontrol edin.',
        icon: Icons.mark_email_read_outlined,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (p, s) => p.status != s.status,
        listener: (context, s) {
          if (s.status == AuthStatus.authenticated) {
            Navigator.pushReplacementNamed(context, '/notes');
          }
          if (s.error != null && s.error!.trim().isNotEmpty) {
            _showSnack(s.error!, icon: Icons.error_outline);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(65, 238, 180, 34),
                Color.fromARGB(159, 205, 197, 191),
                Color.fromARGB(65, 238, 180, 34),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 28,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 8),
                      _GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 8),
                            Image.asset('assets/logo.png', height: 100),
                            const SizedBox(height: 20),

                            // Ad Soyad
                            _GlassTextField(
                              controller: _fullName,
                              hint: 'Ad Soyad',
                              icon: Icons.person_2,
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 12),

                            // E-mail
                            _GlassTextField(
                              controller: _email,
                              hint: 'E-mail',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),

                            // Şifre + göz ikonu
                            _GlassTextField(
                              controller: _pass,
                              hint: 'Şifre',
                              icon: Icons.lock,
                              obscureText: !_showPass,
                              keyboardType: TextInputType.visiblePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _showPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.black45,
                                ),
                                onPressed: () =>
                                    setState(() => _showPass = !_showPass),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Kayıt Ol butonu — Login sayfasıyla birebir aynı stil
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, s) {
                                final busy =
                                    s.status == AuthStatus.authenticating;
                                return SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: GestureDetector(
                                    onTap: busy ? null : _submit,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          colors: busy
                                              ? [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400,
                                                ]
                                              : const [
                                                  Color.fromARGB(
                                                    255,
                                                    238,
                                                    180,
                                                    34,
                                                  ),
                                                  Color.fromARGB(
                                                    255,
                                                    238,
                                                    180,
                                                    34,
                                                  ),
                                                ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: busy
                                          ? const CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            )
                                          : const Text(
                                              'Kayıt Ol',
                                              style: TextStyle(
                                                color: Colors.black45,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Hesabın var mı? Giriş yap",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cam (glass) kart
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Cam tarzı TextField
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.black45, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: const TextStyle(color: Colors.black45),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: const TextStyle(
                      color: Colors.black45,
                      fontSize: 15,
                    ),
                    suffixIcon: suffix,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
