import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'auth_storage.dart';
import 'shopify_auth_service.dart';
import 'order_detail_page.dart';
import 'edit_profile_page.dart';
import 'edit_address_page.dart';

class AccountPage extends StatefulWidget {
  final ShopifyAuthService auth;

  const AccountPage({
    super.key,
    required this.auth,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _customer;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final token = await AuthStorage.readToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Nicht eingeloggt.';
          _loading = false;
        });
        return;
      }

      final customer = await widget.auth.fetchCustomerWithOrders(token);

      if (customer == null) {
        setState(() {
          _error = 'Kundendaten konnten nicht geladen werden.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _customer = customer;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nicht eingeloggt.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adresse löschen'),
        content: const Text('Möchtest du diese Adresse wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.auth.deleteCustomerAddress(
        accessToken: token,
        addressId: addressId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse gelöscht')),
      );

      _loadAccount();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _setDefaultAddress(String addressId) async {
    final token = await AuthStorage.readToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nicht eingeloggt.')),
      );
      return;
    }

    try {
      await widget.auth.setDefaultCustomerAddress(
        accessToken: token,
        addressId: addressId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Standardadresse gesetzt')),
      );

      _loadAccount();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd.MM.yyyy', 'de_CH').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final orders =
        ((_customer?['orders']?['edges'] as List?) ?? [])
            .cast<Map<String, dynamic>>();

    final addresses =
        ((_customer?['addresses']?['edges'] as List?) ?? [])
            .cast<Map<String, dynamic>>();

    final defaultAddressId =
        _customer?['defaultAddress']?['id']?.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Mein Konto',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditAddressPage(auth: widget.auth),
                  ),
                );
                if (ok == true) {
                  _loadAccount();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDFC876),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Adresse hinzufügen',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadAccount,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        100 + MediaQuery.of(context).viewPadding.bottom,
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi ${(_customer?['firstName'] ?? '').toString()}',
                                style: const TextStyle(
                                  color: Color(0xFFDFC876),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (_customer?['email'] ?? '').toString(),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              if ((_customer?['phone'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  (_customer?['phone'] ?? '').toString(),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final ok = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditProfilePage(
                                          auth: widget.auth,
                                          customer: _customer!,
                                        ),
                                      ),
                                    );
                                    if (ok == true) {
                                      _loadAccount();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDFC876),
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text(
                                    'Profil bearbeiten',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Adressen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (addresses.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: const Text(
                              'Noch keine Adressen vorhanden.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),

                        ...addresses.map((edge) {
                          final a = edge['node'] as Map<String, dynamic>;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'
                                      .trim(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((a['company'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    a['company'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                Text(
                                  a['address1']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                if ((a['address2'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    a['address2'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                Text(
                                  '${a['zip'] ?? ''} ${a['city'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                if ((a['country'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    a['country'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),

                                const SizedBox(height: 10),

                                if (a['id']?.toString() == defaultAddressId)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDFC876)
                                          .withOpacity(0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFFDFC876)
                                            .withOpacity(0.55),
                                      ),
                                    ),
                                    child: const Text(
                                      'Standardadresse',
                                      style: TextStyle(
                                        color: Color(0xFFDFC876),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final ok =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditAddressPage(
                                              auth: widget.auth,
                                              address: a,
                                            ),
                                          ),
                                        );
                                        if (ok == true) {
                                          _loadAccount();
                                        }
                                      },
                                      child: const Text(
                                        'Bearbeiten',
                                        style: TextStyle(
                                          color: Color(0xFFDFC876),
                                        ),
                                      ),
                                    ),
                                    if (a['id']?.toString() !=
                                        defaultAddressId)
                                      TextButton(
                                        onPressed: () => _setDefaultAddress(
                                          a['id'].toString(),
                                        ),
                                        child: const Text(
                                          'Als Standard',
                                          style: TextStyle(
                                            color: Color(0xFFDFC876),
                                          ),
                                        ),
                                      ),
                                    TextButton(
                                      onPressed: () => _deleteAddress(
                                        a['id'].toString(),
                                      ),
                                      child: const Text(
                                        'Löschen',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 18),

                        const Text(
                          'Bestellungen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (orders.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: const Text(
                              'Noch keine Bestellungen vorhanden.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),

                        ...orders.map((edge) {
                          final order = edge['node'] as Map<String, dynamic>;
                          final total =
                              order['totalPrice'] as Map<String, dynamic>?;
                          final amount =
                              total?['amount']?.toString() ?? '';
                          final currency =
                              total?['currencyCode']?.toString() ?? '';

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OrderDetailPage(order: order),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order['name']?.toString() ??
                                        'Bestellung',
                                    style: const TextStyle(
                                      color: Color(0xFFDFC876),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Datum: ${_fmtDate(order['processedAt']?.toString())}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status Zahlung: ${order['financialStatus'] ?? '-'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status Versand: ${order['fulfillmentStatus'] ?? '-'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$amount $currency',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tippen für Details',
                                    style: TextStyle(
                                      color: Color(0xFFDFC876),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
    );
  }
}