import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

const Color kGastroBg = Color.fromARGB(255, 0, 0, 0);
const Color kGastroText = Color.fromARGB(255, 223, 223, 223);
const Color kGastroGold = Color(0xFFDFC876);
const Color kGastroBorder = Color(0xFFEAEAEA);

class GastroPage extends StatefulWidget {
  const GastroPage({super.key});

  @override
  State<GastroPage> createState() => _GastroPageState();
}

class _GastroPageState extends State<GastroPage> {
  late Future<List<GastroProduct>> _futureProducts;

  @override
  void initState() {
    super.initState();
    _futureProducts = GastroShopifyApi.fetchGastroProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGastroBg,
      appBar: AppBar(
        backgroundColor: kGastroGold,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'B2B',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
      ),
     body: SafeArea(
  child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _futureProducts = GastroShopifyApi.fetchGastroProducts();
          });
        },
      child: ListView(
  physics: const AlwaysScrollableScrollPhysics(),
  padding: EdgeInsets.fromLTRB(
    16,
    16,
    16,
    MediaQuery.of(context).padding.bottom + 80,
  ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Willkommen im B2B Bereich',
                    style: TextStyle(
                      color: kGastroGold,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Unser exklusives Sortiment für Gastronomie, Grosskunden und Wiederverkäufer.',
                    style: TextStyle(
                      color: kGastroText,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Sortimentsübersicht',
              style: TextStyle(
                color: kGastroGold,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 10),

            FutureBuilder<List<GastroProduct>>(
              future: _futureProducts,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snap.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 34,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fehler beim Laden der Gastro-Produkte:\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: kGastroGold,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _futureProducts =
                                  GastroShopifyApi.fetchGastroProducts();
                            });
                          },
                          child: const Text(
                            'Erneut laden',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final products = snap.data ?? [];
                if (products.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'In der Shopify-Collection "gastro" wurden noch keine Produkte gefunden.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  padding: const EdgeInsets.only(top: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return _GastroProductCard(
                      product: p,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GastroProductWebViewPage(
                              title: p.title,
                              url: 'https://shrimpshop.ch/products/${p.handle}',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
        ),
 ),
);   
    
  }
}

class _GastroProductCard extends StatelessWidget {
  final GastroProduct product;
  final VoidCallback onTap;

  const _GastroProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        color: kGastroBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: kGastroBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: Center(
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kGastroText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.compareAtPrice != null &&
                      product.compareAtPrice! > product.price)
                    Text(
                      _formatCHF(product.compareAtPrice!),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    _formatCHF(product.price),
                    style: const TextStyle(
                      color: kGastroGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
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

class GastroProductWebViewPage extends StatefulWidget {
  final String title;
  final String url;

  const GastroProductWebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<GastroProductWebViewPage> createState() =>
      _GastroProductWebViewPageState();
}

class _GastroProductWebViewPageState extends State<GastroProductWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGastroBg,
      appBar: AppBar(
        backgroundColor: kGastroGold,
        foregroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

class GastroProduct {
  final String title;
  final String handle;
  final String imageUrl;
  final double price;
  final double? compareAtPrice;

  GastroProduct({
    required this.title,
    required this.handle,
    required this.imageUrl,
    required this.price,
    this.compareAtPrice,
  });
}

class GastroShopifyApi {
  static const String publicStorefrontToken =
      '33479b3363169a76f9525da631b6f2c9';
  static const String shopDomain = 'shrimpshopswiss.myshopify.com';
  static const String apiVersion = '2024-10';
  static const String gastroCollectionHandle = 'gastro';

  static Uri get endpoint =>
      Uri.https(shopDomain, '/api/$apiVersion/graphql.json');

  static Future<Map<String, dynamic>> _postGraphQL(
    String query,
    Map<String, dynamic> variables,
  ) async {
    final res = await http.post(
      endpoint,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Shopify-Storefront-Access-Token': publicStorefrontToken.trim(),
      },
      body: jsonEncode({
        'query': query,
        'variables': variables,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (data['errors'] != null) {
      throw Exception('GraphQL errors: ${data['errors']}');
    }

    return data;
  }

  static Future<List<GastroProduct>> fetchGastroProducts() async {
    const query = r'''
query CollectionProducts($handle: String!, $first: Int!) {
  collection(handle: $handle) {
    products(first: $first, sortKey: CREATED, reverse: true) {
      edges {
        node {
          title
          handle
          featuredImage { url }
          variants(first: 1) {
            edges {
              node {
                price { amount }
                compareAtPrice { amount }
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
      'handle': gastroCollectionHandle,
      'first': 100,
    });

    final collection = data['data']?['collection'];
    if (collection == null) return [];

    final edges = (collection['products']?['edges'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return edges.map((e) {
      final node = e['node'] as Map<String, dynamic>;
      final img = node['featuredImage'] as Map<String, dynamic>?;
      final variantEdges = (node['variants']?['edges'] as List? ?? []);

      double price = 0;
      double? compareAtPrice;

      if (variantEdges.isNotEmpty) {
        final firstVariant = variantEdges.first['node'] as Map<String, dynamic>;
        final priceStr =
            (firstVariant['price']?['amount'] as String?) ?? '0';
        price = double.tryParse(priceStr) ?? 0;

        final compareStr =
            firstVariant['compareAtPrice']?['amount'] as String?;
        compareAtPrice =
            compareStr == null ? null : double.tryParse(compareStr);
      }

      return GastroProduct(
        title: (node['title'] as String?) ?? '',
        handle: (node['handle'] as String?) ?? '',
        imageUrl:
            (img?['url'] as String?) ??
            'https://via.placeholder.com/600x600.png?text=ShrimpShop',
        price: price,
        compareAtPrice: compareAtPrice,
      );
    }).where((p) => p.handle.isNotEmpty).toList();
  }
}

String _formatCHF(double v) => '${v.toStringAsFixed(2)} CHF';