import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';
import 'home_screens.dart';

InputDecoration _roundedFieldDecoration(String label, Color focusColor, {IconData? icon}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: focusColor, width: 1.4),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(apiUrlUsuarios));
      if (response.statusCode == 200) {
        final usuarios = json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        final correoIngresado = _correoCtrl.text.trim().toLowerCase();
        final contrasenaIngresada = _passCtrl.text.trim();

        dynamic usuarioValido;
        for (final u in usuarios) {
          if ((u['correo'] ?? '').toString().trim().toLowerCase() == correoIngresado &&
              (u['contrasena'] ?? '').toString().trim() == contrasenaIngresada) {
            usuarioValido = u;
            break;
          }
        }

        if (usuarioValido != null) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(
                userId: usuarioValido['id'],
                userName: usuarioValido['nombre'],
              ),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales incorrectas'), backgroundColor: Colors.red),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error del servidor: ${response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.travel_explore, size: 40, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'TalcaTravel Tech',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accede con tu cuenta para continuar',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _roundedFieldDecoration('Correo Electrónico', const Color(0xFF2563EB), icon: Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        decoration: _roundedFieldDecoration('Contraseña', const Color(0xFF2563EB), icon: Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Ver contraseña' : 'Ocultar contraseña',
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _login,
                                child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        ),
                        child: const Text('¿No tienes cuenta? Regístrate aquí'),
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  void _showFeedbackSnackBar(String message, {required Color backgroundColor, required IconData icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _extractServerMessage(String responseBody) {
    final trimmedBody = responseBody.trim();
    if (trimmedBody.isEmpty) {
      return 'No se pudo completar el registro.';
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded['detail'] ?? decoded['message'] ?? decoded['error'] ?? decoded['non_field_errors'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }

        final entries = decoded.entries
            .map((entry) => '${entry.key}: ${entry.value is List ? (entry.value as List).join(', ') : entry.value}')
            .join('\n');
        if (entries.isNotEmpty) {
          return entries;
        }
      }
    } catch (_) {
      // Si no es JSON, se usa el texto plano.
    }

    return trimmedBody.replaceAll(RegExp(r'^[\{\[\"]+|[\}\]\"]+$'), '');
  }

  Future<void> _registrar() async {
    if (isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    final body = {
      'nombre': _nombreCtrl.text.trim(),
      'correo': _correoCtrl.text.trim().toLowerCase(),
      'contrasena': _passCtrl.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrlUsuarios),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        _showFeedbackSnackBar(
          'Registro exitoso. Inicia sesión.',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        Navigator.pop(context);
      } else {
        final message = _extractServerMessage(response.body);
        _showFeedbackSnackBar(
          message,
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      _showFeedbackSnackBar(
        'Error de conexión: $e',
        backgroundColor: Colors.red,
        icon: Icons.wifi_off,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.person_add_alt_1, size: 40, color: Color(0xFF059669)),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Completa tus datos para registrarte',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _nombreCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _roundedFieldDecoration('Nombre Completo', const Color(0xFF059669), icon: Icons.person_outline),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _correoCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _roundedFieldDecoration('Correo Electrónico', const Color(0xFF059669), icon: Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        decoration: _roundedFieldDecoration('Contraseña', const Color(0xFF059669), icon: Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Ver contraseña' : 'Ocultar contraseña',
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _registrar,
                                child: const Text('Crear Cuenta', style: TextStyle(fontSize: 18)),
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