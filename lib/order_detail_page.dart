import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd.MM.yyyy', 'de_CH').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final total = order['totalPrice'] as Map<String, dynamic>?;
    final lineItems =
        ((order['lineItems']?['edges'] as List?) ?? [])
            .cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        elevation: 0,
        title: Text(
          (order['name'] ?? 'Bestellung').toString(),
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
                    (order['name'] ?? 'Bestellung').toString(),
                    style: const TextStyle(
                      color: Color(0xFFDFC876),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Datum: ${_fmtDate(order['processedAt']?.toString())}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zahlung: ${(order['financialStatus'] ?? '-').toString()}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versand: ${(order['fulfillmentStatus'] ?? '-').toString()}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(total?['amount'] ?? '').toString()} ${(total?['currencyCode'] ?? '').toString()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Artikel',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...lineItems.map((edge) {
              final item = edge['node'] as Map<String, dynamic>;
              final price = item['originalTotalPrice'] as Map<String, dynamic>?;

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
                      (item['title'] ?? '').toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item['variant']?['title'] != null)
                      Text(
                        item['variant']['title'].toString(),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Menge: ${(item['quantity'] ?? 0).toString()}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(price?['amount'] ?? '').toString()} ${(price?['currencyCode'] ?? '').toString()}',
                      style: const TextStyle(
                        color: Color(0xFFDFC876),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}