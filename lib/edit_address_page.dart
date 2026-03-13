import 'package:flutter/material.dart';
import 'auth_storage.dart';
import 'shopify_auth_service.dart';

class EditAddressPage extends StatefulWidget {
  final ShopifyAuthService auth;
  final Map<String, dynamic>? address;

  const EditAddressPage({
    super.key,
    required this.auth,
    this.address,
  });

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _address1Ctrl;
  late final TextEditingController _address2Ctrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _phoneCtrl;

  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;

    _firstCtrl = TextEditingController(text: (a?['firstName'] ?? '').toString());
    _lastCtrl = TextEditingController(text: (a?['lastName'] ?? '').toString());
    _companyCtrl = TextEditingController(text: (a?['company'] ?? '').toString());
    _address1Ctrl = TextEditingController(text: (a?['address1'] ?? '').toString());
    _address2Ctrl = TextEditingController(text: (a?['address2'] ?? '').toString());
    _zipCtrl = TextEditingController(text: (a?['zip'] ?? '').toString());
    _cityCtrl = TextEditingController(text: (a?['city'] ?? '').toString());
    _provinceCtrl = TextEditingController(text: (a?['province'] ?? '').toString());
    _countryCtrl = TextEditingController(
      text: (a?['country'] ?? 'Switzerland').toString(),
    );
    _phoneCtrl = TextEditingController(text: (a?['phone'] ?? '').toString());
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _companyCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
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

      final address = {
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'address1': _address1Ctrl.text.trim(),
        'address2': _address2Ctrl.text.trim(),
        'zip': _zipCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'province': _provinceCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      if (_isEdit) {
        await widget.auth.updateCustomerAddress(
          accessToken: token,
          addressId: widget.address!['id'].toString(),
          address: address,
        );
      } else {
        await widget.auth.createCustomerAddress(
          accessToken: token,
          address: address,
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
          _isEdit ? 'Adresse bearbeiten' : 'Adresse hinzufügen',
          style: const TextStyle(color: Colors.white),
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
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _lastCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Nachname'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _companyCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Firma'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _address1Ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Adresse 1'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bitte Adresse eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _address2Ctrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Adresse 2'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _zipCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('PLZ'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bitte PLZ eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _cityCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Ort'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bitte Ort eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _provinceCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Kanton / Region'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _countryCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Land'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Bitte Land eingeben.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _deco('Telefon'),
                    keyboardType: TextInputType.phone,
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
                          : Text(
                              _isEdit
                                  ? 'Adresse speichern'
                                  : 'Adresse hinzufügen',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
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