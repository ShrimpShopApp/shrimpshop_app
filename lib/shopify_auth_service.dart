import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopifyAuthService {
  final String shopDomain;
  final String storefrontAccessToken;

  ShopifyAuthService({
    required this.shopDomain,
    required this.storefrontAccessToken,
  });

  Uri get _endpoint => Uri.https(shopDomain, '/api/2024-10/graphql.json');

static const String appCustomerTagEndpoint =
    'https://swissprimetaste.ch/api/tag-mobileapp-customer.php';

Future<void> markCustomerAsMobileApp({
  required String customerAccessToken,
}) async {
  final res = await http.post(
    Uri.parse(appCustomerTagEndpoint),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'customerAccessToken': customerAccessToken,
    }),
  );

  print('TAG STATUS: ${res.statusCode}');
  print('TAG BODY: ${res.body}');

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Tagging failed: ${res.statusCode} ${res.body}');
  }

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (body['ok'] != true) {
    throw Exception('Tagging failed: ${res.body}');
  }
}


  Future<Map<String, dynamic>> _postGraphQL(
    String query,
    Map<String, dynamic> variables,
  ) async {
    final res = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': storefrontAccessToken,
      },
      body: jsonEncode({
        'query': query,
        'variables': variables,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Shopify HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;

    if (body['errors'] != null) {
      throw Exception('Shopify GraphQL errors: ${body['errors']}');
    }

    return body['data'] as Map<String, dynamic>;
  }

    Future<String> createCustomer({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    bool acceptsMarketing = false,
  }) async {
    const mutation = r'''
      mutation customerCreate($input: CustomerCreateInput!) {
        customerCreate(input: $input) {
          customer { id }
          customerUserErrors { field message code }
        }
      }
    ''';

    final data = await _postGraphQL(mutation, {
      'input': {
        'email': email,
        'password': password,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        'acceptsMarketing': acceptsMarketing,
      },
    });

    final result = data['customerCreate'] as Map<String, dynamic>;
    final errors =
        (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

    if (errors.isNotEmpty) {
      final msg = errors.map((e) => e['message']).join('\n');
      throw Exception(msg);
    }

    final accessToken = await loginAndGetAccessToken(
      email: email,
      password: password,
    );

    return accessToken;
  }



  Future<Map<String, dynamic>?> fetchCustomer(String accessToken) async {
    const query = r'''
      query getCustomer($token: String!) {
        customer(customerAccessToken: $token) {
          firstName
          lastName
          email
        }
      }
    ''';

    final data = await _postGraphQL(query, {
      'token': accessToken,
    });

    return data['customer'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> fetchCustomerWithOrders(
    String accessToken,
  ) async {
    const query = r'''
      query getCustomerWithOrders($token: String!) {
        customer(customerAccessToken: $token) {
          id
          firstName
          lastName
          email
          phone
          defaultAddress {
            id
            firstName
            lastName
            company
            address1
            address2
            zip
            city
            province
            country
            phone
          }
          addresses(first: 20) {
            edges {
              node {
                id
                firstName
                lastName
                company
                address1
                address2
                zip
                city
                province
                country
                phone
              }
            }
          }
          orders(first: 20, sortKey: PROCESSED_AT, reverse: true) {
            edges {
              node {
                id
                name
                orderNumber
                processedAt
                financialStatus
                fulfillmentStatus
                totalPrice {
                  amount
                  currencyCode
                }
                lineItems(first: 50) {
                  edges {
                    node {
                      title
                      quantity
                      currentQuantity
                      variant {
                        title
                      }
                      originalTotalPrice {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''';

    final data = await _postGraphQL(query, {
      'token': accessToken,
    });

    return data['customer'] as Map<String, dynamic>?;
  }

  Future<String> loginAndGetAccessToken({
    required String email,
    required String password,
  }) async {
    const mutation = r'''
      mutation customerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
        customerAccessTokenCreate(input: $input) {
          customerAccessToken {
            accessToken
            expiresAt
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final data = await _postGraphQL(mutation, {
      'input': {
        'email': email,
        'password': password,
      },
    });

    final result = data['customerAccessTokenCreate'] as Map<String, dynamic>;
    final errors =
        (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

    if (errors.isNotEmpty) {
      final msg = errors.map((e) => e['message']).join('\n');
      throw Exception(msg);
    }

       final tokenObj = result['customerAccessToken'] as Map<String, dynamic>?;
    if (tokenObj == null) {
      throw Exception('Kein Access Token erhalten.');
    }

   final accessToken = tokenObj['accessToken'] as String;

await markCustomerAsMobileApp(
  customerAccessToken: accessToken,
);

return accessToken;
  }

  Future<Map<String, dynamic>> updateCustomerProfile({
    required String accessToken,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    const mutation = r'''
      mutation customerUpdate(
        $customerAccessToken: String!,
        $customer: CustomerUpdateInput!
      ) {
        customerUpdate(
          customerAccessToken: $customerAccessToken,
          customer: $customer
        ) {
          customer {
            firstName
            lastName
            email
            phone
          }
          customerAccessToken {
            accessToken
            expiresAt
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final data = await _postGraphQL(mutation, {
      'customerAccessToken': accessToken,
      'customer': {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    });

    final result = data['customerUpdate'] as Map<String, dynamic>;
    final errors =
        (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

    if (errors.isNotEmpty) {
      final msg = errors.map((e) => e['message']).join('\n');
      throw Exception(msg);
    }

    return result;
  }

  Future<void> createCustomerAddress({
    required String accessToken,
    required Map<String, dynamic> address,
  }) async {
    const mutation = r'''
      mutation customerAddressCreate(
        $customerAccessToken: String!,
        $address: MailingAddressInput!
      ) {
        customerAddressCreate(
          customerAccessToken: $customerAccessToken,
          address: $address
        ) {
          customerAddress {
            id
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final data = await _postGraphQL(mutation, {
      'customerAccessToken': accessToken,
      'address': address,
    });

    final result = data['customerAddressCreate'] as Map<String, dynamic>;
    final errors =
        (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

    if (errors.isNotEmpty) {
      final msg = errors.map((e) => e['message']).join('\n');
      throw Exception(msg);
    }
  }

  Future<void> updateCustomerAddress({
    required String accessToken,
    required String addressId,
    required Map<String, dynamic> address,
  }) async {
    const mutation = r'''
      mutation customerAddressUpdate(
        $customerAccessToken: String!,
        $id: ID!,
        $address: MailingAddressInput!
      ) {
        customerAddressUpdate(
          customerAccessToken: $customerAccessToken,
          id: $id,
          address: $address
        ) {
          customerAddress {
            id
          }
          customerUserErrors {
            field
            message
            code
          }
        }
      }
    ''';

    final data = await _postGraphQL(mutation, {
      'customerAccessToken': accessToken,
      'id': addressId,
      'address': address,
    });

    final result = data['customerAddressUpdate'] as Map<String, dynamic>;
    final errors =
        (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

    if (errors.isNotEmpty) {
      final msg = errors.map((e) => e['message']).join('\n');
      throw Exception(msg);
    }
  }

Future<void> deleteCustomerAddress({
  required String accessToken,
  required String addressId,
}) async {
  const mutation = r'''
    mutation customerAddressDelete(
      $customerAccessToken: String!,
      $id: ID!
    ) {
      customerAddressDelete(
        customerAccessToken: $customerAccessToken,
        id: $id
      ) {
        deletedCustomerAddressId
        customerUserErrors {
          field
          message
          code
        }
      }
    }
  ''';

  final data = await _postGraphQL(mutation, {
    'customerAccessToken': accessToken,
    'id': addressId,
  });

  final result = data['customerAddressDelete'] as Map<String, dynamic>;
  final errors =
      (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

  if (errors.isNotEmpty) {
    final msg = errors.map((e) => e['message']).join('\n');
    throw Exception(msg);
  }
}

Future<void> setDefaultCustomerAddress({
  required String accessToken,
  required String addressId,
}) async {
  const mutation = r'''
    mutation customerDefaultAddressUpdate(
      $customerAccessToken: String!,
      $addressId: ID!
    ) {
      customerDefaultAddressUpdate(
        customerAccessToken: $customerAccessToken,
        addressId: $addressId
      ) {
        customer {
          defaultAddress {
            id
          }
        }
        customerUserErrors {
          field
          message
          code
        }
      }
    }
  ''';

  final data = await _postGraphQL(mutation, {
    'customerAccessToken': accessToken,
    'addressId': addressId,
  });

  final result = data['customerDefaultAddressUpdate'] as Map<String, dynamic>;
  final errors =
      (result['customerUserErrors'] as List).cast<Map<String, dynamic>>();

  if (errors.isNotEmpty) {
    final msg = errors.map((e) => e['message']).join('\n');
    throw Exception(msg);
  }
}


}