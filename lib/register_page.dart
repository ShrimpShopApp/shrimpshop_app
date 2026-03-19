import 'package:flutter/material.dart';
import 'shopify_auth_service.dart';
import 'auth_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  final ShopifyAuthService auth;
  final bool isGastro;

  const RegisterPage({
    super.key,
    required this.auth,
    this.isGastro = false,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  bool _marketing = false;
  bool _loading = false;
  bool _obscurePw = true;
  bool _obscurePw2 = true;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(
    String label, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent),
    );
  }


Future<void> _notifyGastroRegistration({
  required String email,
  required String firstName,
  required String lastName,
}) async {
  final uri = Uri.parse('https://swissprimetaste.ch/api/gastro-register.php?v=3');
  debugPrint('GASTRO URL: $uri');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'source': 'app',
      'tag': 'gastro',
    }),
  );

  debugPrint('GASTRO status: ${response.statusCode}');
  debugPrint('GASTRO body: ${response.body}');

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Gastro-Tag konnte nicht gesetzt werden. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  final data = jsonDecode(response.body);

  if (data is Map && data['ok'] != true) {
    throw Exception(
      data['error']?.toString() ?? 'Unbekannter Fehler beim Gastro-Tagging.',
    );
  }
}

Future<void> _notifyMobileAppRegistration({
  required String customerAccessToken,
}) async {
  final uri = Uri.parse(
    'https://swissprimetaste.ch/api/tag-mobileapp-customer.php',
  );

  debugPrint('MOBILEAPP URL: $uri');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'customerAccessToken': customerAccessToken,
    }),
  );

  debugPrint('MOBILEAPP status: ${response.statusCode}');
  debugPrint('MOBILEAPP body: ${response.body}');

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'MobileApp-Tag konnte nicht gesetzt werden. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  final data = jsonDecode(response.body);

  if (data is Map && data['ok'] != true) {
    throw Exception(
      data['error']?.toString() ?? 'Unbekannter Fehler beim MobileApp-Tagging.',
    );
  }
}


Future<void> _submit() async {
  FocusScope.of(context).unfocus();

  setState(() {
    _error = null;
    _loading = true;
  });

  try {
    if (!_formKey.currentState!.validate()) {
      setState(() => _loading = false);
      return;
    }

    final email = _email.text.trim().toLowerCase();
    final pw = _pw.text;
    final firstName = _first.text.trim();
    final lastName = _last.text.trim();

    final accessToken = await widget.auth.createCustomer(
      email: email,
      password: pw,
      firstName: firstName,
      lastName: lastName,
      acceptsMarketing: _marketing,
    );

    await AuthStorage.saveToken(accessToken);

// ✅ Server informieren
if (widget.isGastro) {
  await _notifyGastroRegistration(
    email: email,
    firstName: firstName,
    lastName: lastName,
  );
} else {
  await _notifyMobileAppRegistration(
    customerAccessToken: accessToken,
  );
}

if (!mounted) return;

Navigator.pop(context, true);

  } catch (e) {
    setState(() {
      _error = e.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        elevation: 0,
                title: Text(
            widget.isGastro ? 'Gastro-Registrierung' : 'Konto erstellen',
            style: const TextStyle(color: Colors.white),
          ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
           Text(
                          widget.isGastro ? 'Als Gastro registrieren' : 'Registrieren',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                                    const SizedBox(height: 6),
                                  Text(
                          widget.isGastro
                              ? 'Für Restaurants, Catering und Wiederverkäufer. Nach der Registrierung wird dein Konto für den Gastro-Bereich markiert.'
                              : 'Schneller Checkout, exklusive App-Angebote und alles an einem Ort.',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _first,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDeco('Vorname', hint: 'Max'),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Bitte Vorname eingeben.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _last,
                            style: const TextStyle(color: Colors.white),
                            textInputAction: TextInputAction.next,
                            decoration: _fieldDeco('Nachname', hint: 'Muster'),
                            validator: (v) {
                              if ((v ?? '').trim().isEmpty) {
                                return 'Bitte Nachname eingeben.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _email,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration:
                          _fieldDeco('E-Mail', hint: 'max@email.ch'),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Bitte E-Mail eingeben.';
                        if (!s.contains('@') || !s.contains('.')) {
                          return 'Ungültige E-Mail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pw,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePw,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDeco(
                        'Passwort',
                        hint: 'Mindestens 8 Zeichen',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscurePw = !_obscurePw);
                          },
                          icon: Icon(
                            _obscurePw
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      validator: (v) {
                        final s = v ?? '';
                        if (s.length < 8) return 'Mindestens 8 Zeichen.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pw2,
                      style: const TextStyle(color: Colors.white),
                      obscureText: _obscurePw2,
                      textInputAction: TextInputAction.done,
                      decoration: _fieldDeco(
                        'Passwort bestätigen',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscurePw2 = !_obscurePw2);
                          },
                          icon: Icon(
                            _obscurePw2
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '') != _pw.text) {
                          return 'Passwörter stimmen nicht überein.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.10)),
                      ),
                      child: SwitchListTile(
                        value: _marketing,
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _marketing = v),
                        title: const Text(
                          'Updates & Angebote per E-Mail',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Optional – jederzeit abbestellbar.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        activeThumbColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.white24,
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                widget.isGastro ? 'Als Gastro registrieren' : 'Konto erstellen',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text(
                      'Mit dem Erstellen eines Kontos stimmst du unseren Richtlinien zu.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}