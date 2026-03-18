import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopifyCustomerService {
  final String shopDomain;
  final String storefrontAccessToken;

  ShopifyCustomerService({
    required this.shopDomain,
    required this.storefrontAccessToken,
  });

  Future<Map<String, dynamic>?> fetchCustomer({
    required String customerAccessToken,
  }) async {
    const query = r'''
      query GetCustomer($customerAccessToken: String!) {
        customer(customerAccessToken: $customerAccessToken) {
          id
          firstName
          lastName
          email
          tags
        }
      }
    ''';

    final uri = Uri.parse('https://$shopDomain/api/2026-01/graphql.json');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': storefrontAccessToken,
      },
      body: jsonEncode({
        'query': query,
        'variables': {
          'customerAccessToken': customerAccessToken,
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Customer query failed: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['errors'] != null) {
      throw Exception('GraphQL errors: ${json['errors']}');
    }

    final data = json['data'] as Map<String, dynamic>?;
    return data?['customer'] as Map<String, dynamic>?;
  }

  Future<bool> isGastroCustomer({
    required String customerAccessToken,
  }) async {
    final customer = await fetchCustomer(customerAccessToken: customerAccessToken);
    if (customer == null) return false;

    final rawTags = customer['tags'];
    final tags = rawTags is List ? rawTags.map((e) => e.toString().trim().toLowerCase()).toList() : <String>[];

    return tags.contains('gastro');
  }
}