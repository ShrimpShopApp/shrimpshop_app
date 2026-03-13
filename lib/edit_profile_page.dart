import 'package:flutter/material.dart';
import 'auth_storage.dart';
import 'shopify_auth_service.dart';

class EditProfilePage extends StatefulWidget {
  final ShopifyAuthService auth;
  final Map<String, dynamic> customer;

  const EditProfilePage({
    super.key,
    required this.auth,
    required this.customer,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(
      text: (widget.customer['firstName'] ?? '').toString(),
    );
    _lastCtrl = TextEditingController(
      text: (widget.customer['lastName'] ?? '').toString(),
    );
    _emailCtrl = TextEditingController(
      text: (widget.customer['email'] ?? '').toString(),
    );
    _phoneCtrl = TextEditingController(
      text: (widget.customer['phone'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      labelStyle: const TextStyle(color: Colors.white70),
      helperStyle: const TextStyle(color: Colors.white54),
      floatingLabelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white10,
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

  String? _normalizePhone(String rawPhone) {
    var phone = rawPhone.trim();

    if (phone.isEmpty) return null;

    phone = phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('/', '');

    if (phone.startsWith('00')) {
      phone = '+${phone.substring(2)}';
    }

    if (phone.startsWith('0')) {
      phone = '+41${phone.substring(1)}';
    }

    if (!phone.startsWith('+')) {
      phone = '+$phone';
    }

    return phone;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthStorage.readToken();
      if (token == null || token.isEmpty) {
        throw Exception('Nicht eingeloggt.');
      }

      final normalizedPhone = _normalizePhone(_phoneCtrl.text);

      final result = await widget.auth.updateCustomerProfile(
        accessToken: token,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: normalizedPhone,
      );

      final newToken =
          result['customerAccessToken']?['accessToken']?.toString();

      if (newToken != null && newToken.isNotEmpty) {
        await AuthStorage.saveToken(newToken);
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
        title: const Text(
          'Profil bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24 + MediaQuery.of(context).viewPadding.bottom,
          ),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.6),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Vorname'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bitte Vorname eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _lastCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Nachname'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bitte Nachname eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: _deco('E-Mail'),
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
                    controller: _phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: _deco(
                      'Telefon',
                      helperText:
                          'Schweizer Nummern mit 0 werden automatisch zu +41 umgewandelt.',
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;

                      final cleaned = s
                          .replaceAll(' ', '')
                          .replaceAll('-', '')
                          .replaceAll('(', '')
                          .replaceAll(')', '')
                          .replaceAll('/', '');

                      if (cleaned.length < 8) {
                        return 'Telefonnummer ungültig.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDFC876),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.white24,
                        disabledForegroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Speichern',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}