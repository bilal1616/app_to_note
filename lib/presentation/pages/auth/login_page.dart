// ignore_for_file: deprecated_member_use

import 'package:app_to_note/presentation/cubits/auth/auth_cubit.dart';
import 'package:app_to_note/presentation/cubits/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool _showPassword = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // Ortak snackbar
  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          backgroundColor: Colors.white.withOpacity(.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Color.fromARGB(255, 179, 17, 5), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: "TAMAM",
            textColor: const Color.fromARGB(255, 179, 17, 5),
            onPressed: () {},
          ),
        ),
      );
  }

  bool _isValidEmail(String v) =>
      RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(v);

  Future<void> _onLoginPressed(bool loading) async {
    if (loading) return;

    final mail = email.text.trim();
    final pass = password.text;

    if (mail.isEmpty || pass.isEmpty) {
      _showSnack("E-mail ve şifre zorunludur!");
      return;
    }
    if (!_isValidEmail(mail)) {
      _showSnack("Geçerli bir e-mail girin!");
      return;
    }
    if (pass.length < 6) {
      _showSnack("Şifre en az 6 karakter olmalı!");
      return;
    }

    await context.read<AuthCubit>().login(mail, pass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Arka plan
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(70, 238, 180, 34),
              Color.fromARGB(160, 220, 210, 200),
              Color.fromARGB(70, 238, 180, 34),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: BlocListener<AuthCubit, AuthState>(
            listenWhen: (p, n) => n.error != null,
            listener: (context, state) => _showSnack(
              state.error?.isNotEmpty == true
                  ? state.error!
                  : "Giriş işlemi hatalı!",
            ),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final loading = state.status == AuthStatus.authenticating;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(28),
                  width: MediaQuery.of(context).size.width * 0.88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white24, width: 1),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 40,
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/logo.png", height: 90),
                      const SizedBox(height: 26),

                      _input(
                        controller: email,
                        icon: Icons.email,
                        hint: "E-mail",
                      ),
                      const SizedBox(height: 16),

                      _input(
                        controller: password,
                        icon: Icons.lock,
                        hint: "Şifre",
                        isObscure: !_showPassword,
                        suffix: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black45,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Giriş Yap — Register ile birebir aynı tasarım
                      GestureDetector(
                        onTap: () => _onLoginPressed(loading),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 55,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: loading
                                  ? [Colors.grey.shade300, Colors.grey.shade400]
                                  : const [
                                      Color.fromARGB(255, 238, 180, 34),
                                      Color.fromARGB(255, 238, 180, 34),
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                )
                              : const Text(
                                  "Giriş Yap",
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () =>
                                  Navigator.of(context).pushNamed('/register'),
                        child: const Text(
                          "Hesabın yok mu? Kayıt ol",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isObscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(.25),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: Colors.black87),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black45),
          suffixIcon: suffix,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
