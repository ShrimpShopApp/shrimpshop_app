import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'register_page.dart';
import 'shopify_auth_service.dart';
import 'auth_storage.dart';
import 'package:provider/provider.dart';
import 'recipes_page.dart';
import 'login_page.dart';
import 'account_page.dart';
import 'favorites_model.dart';
import 'favorites_page.dart';


/// =======================
/// ShrimpShop Theme
/// =======================
const kAccent = Color.fromARGB(255, 219, 219, 219); // neu
const kText = Color.fromARGB(255, 223, 223, 223);
const kTextMuted = Color(0xFF6B7280);
const kBg = Color.fromARGB(255, 0, 0, 0);
const kCard = Color.fromARGB(255, 0, 0, 0);
const kBorder = Color(0xFFEAEAEA);

final CartModel cart = CartModel();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_CH', null);
  Intl.defaultLocale = 'de_CH';

  final favoritesModel = FavoritesModel();
  await favoritesModel.loadFavorites();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CartModel>.value(value: cart),
        ChangeNotifierProvider<FavoritesModel>.value(value: favoritesModel),
      ],
      child: const ShrimpShopApp(),
    ),
  );
}


class ShrimpShopApp extends StatelessWidget {
  const ShrimpShopApp({super.key});

  @override
  Widget build(BuildContext context) {
  
  return MaterialApp(
    title: 'ShrimpShop',
    debugShowCheckedModeBanner: false,

    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],

    supportedLocales: const [
      Locale('de', 'CH'),
      Locale('de'),
    ],

    locale: const Locale('de', 'CH'),

    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(seedColor: kAccent),
      appBarTheme: const AppBarTheme(
        backgroundColor: kAccent,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: kCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: kBorder),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
      ),
    ),

    home: const SplashPage(),
  
);
  }
}

/// =======================
/// Splash
/// =======================
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (!mounted) return;
      _goNext();
    });
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, animation, _, child) {
          final a = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(opacity: a, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: SizedBox.expand(
          child: Image.asset('assets/splash.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// =======================
/// Models
/// =======================
class Variant {
  final String gid;
  final String title;
  final double price;
  final String numericId;
  final double? compareAtPrice; // ✅ neu

  Variant({
    required this.gid,
    required this.title,
    required this.price,
    required this.numericId,
    this.compareAtPrice,
  });
}

class Product {
  final String gid;
  final String title;
  final String handle;
  final String imageUrl;
  final String description;
  final List<Variant> variants;

  Product({
    required this.gid,
    required this.title,
    required this.handle,
    required this.imageUrl,
    required this.description,
    required this.variants,
  });

  Variant get defaultVariant => variants.isNotEmpty
      ? variants.first
      : Variant(gid: '', title: '', price: 0.0, numericId: '');
}

class ShopCollection {
  final String title;
  final String handle;
  final String imageUrl;

  ShopCollection({
    required this.title,
    required this.handle,
    required this.imageUrl,
  });
}



/// =======================
/// Cart (Variant-basiert)
/// =======================
class CartItem {
  final Product product;
  final Variant variant;
  int qty;

  CartItem({required this.product, required this.variant, this.qty = 1});
}

class CartModel extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get totalQty => _items.values.fold(0, (sum, it) => sum + it.qty);

  double get totalPrice =>
      _items.values.fold(0.0, (sum, it) => sum + it.qty * it.variant.price);

  void add(Product p, Variant v) {
    final key = '${p.gid}::${v.gid}';
    final existing = _items[key];
    if (existing != null) {
      existing.qty += 1;
    } else {
      _items[key] = CartItem(product: p, variant: v, qty: 1);
    }
    notifyListeners();
  }

  void removeOne(Product p, Variant v) {
    final key = '${p.gid}::${v.gid}';
    final existing = _items[key];
    if (existing == null) return;

    existing.qty -= 1;
    if (existing.qty <= 0) _items.remove(key);
    notifyListeners();
  }

  void removeAll(Product p, Variant v) {
    _items.remove('${p.gid}::${v.gid}');
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}


String formatCHF(double v) => '${v.toStringAsFixed(2)} CHF';

String _variantGidToNumeric(String gid) {
  final parts = gid.split('/');
  return parts.isNotEmpty ? parts.last : gid;
}

String sanitizeProductHtml(String html) {
  var s = html;

  // 1) SEO-Kommentarblock entfernen (falls vorhanden)
  s = s.replaceAll(
    RegExp(r'<!--\s*SEO\s*-->.*?(?=<div|<h1|<h2|<p|<ul|<ol|$)', dotAll: true),
    '',
  );

  // 2) <title>...</title> entfernen
  s = s.replaceAll(RegExp(r'<title[\s\S]*?</title>', caseSensitive: false), '');

  // 3) <meta ...> entfernen
  s = s.replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '');

  // 4) optional: alles VOR deiner eigentlichen Beschreibung abschneiden,
  //    z.B. wenn du immer <div class="product-desc"> hast:
  final m = RegExp(
    r'(<div[^>]*class="product-desc"[^>]*>[\s\S]*$)',
    caseSensitive: false,
  ).firstMatch(s);
  if (m != null) s = m.group(1)!;

  return s.trim();
}

/// =======================
/// Shopify Storefront API
/// =======================
class ShopifyStorefrontApi {
  static const String publicStorefrontToken =
      'a63ce8059e3787853a8608a90ff00378';
  static const String shopDomain = 'shrimpshopswiss.myshopify.com';
  static const String apiVersion = '2024-10';

  // ✅ Dein Shopify-Menü-Handle (aus Screenshot): "app-kategorien"
  static const String appMenuHandle = 'app-kategorien';

  static Uri get endpoint =>
      Uri.https(shopDomain, '/api/$apiVersion/graphql.json');

  static void _log(String msg) => debugPrint('[Shopify] $msg');

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
      body: jsonEncode({'query': query, 'variables': variables}),
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


static Future<void> updateDeliveryData({
  required String cartId,
  required String lieferdatum,
  required String zeitfenster,
}) async {
  const mutation = r'''
  mutation CartAttributesUpdate($cartId: ID!, $attributes: [AttributeInput!]!) {
    cartAttributesUpdate(cartId: $cartId, attributes: $attributes) {
      cart { id }
      userErrors { message }
    }
  }
  ''';

  final variables = {
  "cartId": cartId,
  "attributes": [
    {"key": "Lieferdatum", "value": lieferdatum},
    {"key": "Lieferzeitfenster", "value": zeitfenster},
  ]
};

  await _postGraphQL(mutation, variables);
}


static Future<String> createCartAndGetCheckoutUrl({
  required List<CartItem> items,
  String? customerAccessToken,
  String? note,
}) async {
  const mutation = r'''
mutation cartCreate($input: CartInput!) {
  cartCreate(input: $input) {
    cart {
      id
      checkoutUrl
    }
    userErrors {
      field
      message
    }
  }
}
''';

  final lines = items
      .where((it) => it.variant.gid.isNotEmpty && it.qty > 0)
      .map((it) => {
            'merchandiseId': it.variant.gid,
            'quantity': it.qty,
          })
      .toList();

  final input = <String, dynamic>{
    'lines': lines,
  };

  if (customerAccessToken != null && customerAccessToken.trim().isNotEmpty) {
    input['buyerIdentity'] = {
      'customerAccessToken': customerAccessToken.trim(),
    };
  }

  if (note != null && note.trim().isNotEmpty) {
    input['note'] = note.trim();
  }

  final data = await _postGraphQL(mutation, {
    'input': input,
  });

  final result = data['data']?['cartCreate'] as Map<String, dynamic>?;
  if (result == null) {
    throw Exception('cartCreate hat keine Daten zurückgegeben.');
  }

  final errors =
      (result['userErrors'] as List? ?? []).cast<Map<String, dynamic>>();
  if (errors.isNotEmpty) {
    final msg = errors.map((e) => e['message']).join('\n');
    throw Exception(msg);
  }

  final cart = result['cart'] as Map<String, dynamic>?;
  final checkoutUrl = cart?['checkoutUrl'] as String?;

  if (checkoutUrl == null || checkoutUrl.isEmpty) {
    throw Exception('Keine checkoutUrl von Shopify erhalten.');
  }

  return checkoutUrl;
}


  /// ✅ HOME: Nur Collections, die im Shopify-Menü "Kategorien" (app-kategorien) stehen
  /// Fallback: wenn Menü fehlt/leer -> normale Collections laden
  static Future<List<ShopCollection>> fetchAppNavigation() async {
    // 1) Menü laden
    const menuQuery = r'''
query GetMenu($handle: String!) {
  menu(handle: $handle) {
    items {
      title
      url
      items {
        title
        url
      }
    }
  }
}
''';

    final menuData = await _postGraphQL(menuQuery, {'handle': appMenuHandle});
    final menu = menuData['data']?['menu'];

    if (menu == null) {
      _log(
        'menu(handle: "$appMenuHandle") is NULL -> fallback to fetchCollections()',
      );
      return fetchCollections(first: 30);
    }

    // Menü ist hierarchisch möglich: items + subitems
    List<Map<String, dynamic>> flatItems = [];
    final topItems = (menu['items'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    for (final it in topItems) {
      flatItems.add(it);
      final children = (it['items'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      flatItems.addAll(children);
    }

    // 2) aus URLs Collection-Handles extrahieren + Menü-Bezeichnung merken
    final Map<String, String> handleToMenuTitle = {};

    for (final it in flatItems) {
      final url = (it['url'] as String?) ?? '';
      final menuTitle = ((it['title'] as String?) ?? '').trim();

      final h = _extractCollectionHandle(url);
      if (h.isNotEmpty) {
        // falls doppelt: erster gewinnt (oder du überschreibst bewusst)
        handleToMenuTitle.putIfAbsent(h, () => menuTitle);
      }
    }

    if (handleToMenuTitle.isEmpty) {
      _log(
        'Menu has no /collections/... urls -> fallback to fetchCollections()',
      );
      return fetchCollections(first: 30);
    }

    // 3) pro Handle echte Collection (Bild/Handle) laden,
    //    aber Titel aus dem Menü verwenden
    final futures = handleToMenuTitle.entries.map((e) {
      return _fetchCollectionByHandle(e.key, overrideTitle: e.value);
    }).toList();

    final results = await Future.wait(futures);
    final collections = results.whereType<ShopCollection>().toList();

    if (collections.isEmpty) {
      _log(
        'No collections resolved from handles -> fallback to fetchCollections()',
      );
      return fetchCollections(first: 30);
    }

    return collections;
  }

  static String _extractCollectionHandle(String url) {
    // Beispiele:
    // https://shrimpshop.ch/collections/gerauchert
    // /collections/gerauchert
    // https://shrimpshop.ch/collections/gerauchert?sort_by=...
    final u = url.trim();
    final idx = u.indexOf('/collections/');
    if (idx == -1) return '';
    final after = u.substring(idx + '/collections/'.length);
    final noQuery = after.split('?').first;
    final handle = noQuery.split('/').first.trim();
    return handle;
  }

  static Future<ShopCollection?> _fetchCollectionByHandle(
    String handle, {
    String? overrideTitle,
  }) async {
    const query = r'''
query GetCollection($handle: String!) {
  collection(handle: $handle) {
    title
    handle
    image { url }
  }
}
''';
    final data = await _postGraphQL(query, {'handle': handle});
    final c = data['data']?['collection'];
    if (c == null) return null;

    final shopTitle = ((c['title'] as String?) ?? '').trim();
    final menuTitle = (overrideTitle ?? '').trim();

    return ShopCollection(
      // ✅ hier entscheidend:
      title: menuTitle.isNotEmpty ? menuTitle : shopTitle,
      handle: (c['handle'] as String?) ?? '',
      imageUrl:
          (c['image']?['url'] as String?) ??
          'https://via.placeholder.com/600x600.png?text=ShrimpShop',
    );
  }

  /// Fallback: normale Collections
  static Future<List<ShopCollection>> fetchCollections({int first = 30}) async {
    const query = r'''
query Collections($first: Int!) {
  collections(first: $first, sortKey: UPDATED_AT, reverse: true) {
    edges {
      node {
        title
        handle
        image { url }
      }
    }
  }
}
''';

    final data = await _postGraphQL(query, {'first': first});
    final edges = (data['data']?['collections']?['edges'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return edges
        .map((e) {
          final node = e['node'] as Map<String, dynamic>;
          final img = node['image'] as Map<String, dynamic>?;

          return ShopCollection(
            title: (node['title'] as String?) ?? '',
            handle: (node['handle'] as String?) ?? '',
            imageUrl:
                (img?['url'] as String?) ??
                'https://via.placeholder.com/600x600.png?text=ShrimpShop',
          );
        })
        .where((c) => c.handle.isNotEmpty && c.title.isNotEmpty)
        .toList();
  }

  static Future<List<Product>> fetchProducts({int first = 60}) async {
    const query = r'''
query Products($first: Int!) {
  products(first: $first, sortKey: UPDATED_AT, reverse: true) {
    edges {
      node {
        id
        title
        handle
        descriptionHtml
        featuredImage { url }
        variants(first: 50) {
          edges {
            node {
              id
              title
              price { amount }
              compareAtPrice { amount }
            }
          }
        }
      }
    }
  }
}
''';

    final data = await _postGraphQL(query, {'first': first});
    final edges = (data['data']?['products']?['edges'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return edges.map(_mapProductEdge).toList();
  }

  static Future<List<Product>> fetchProductsByCollection({
    required String handle,
    int first = 50,
  }) async {
    const query = r'''
query CollectionProducts($handle: String!, $first: Int!) {
  collection(handle: $handle) {
    products(first: $first, sortKey: CREATED, reverse: true) {
      edges {
        node {
          id
          title
          handle
          descriptionHtml
          featuredImage { url }
          variants(first: 50) {
            edges {
              node {
                id
                title
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

    final data = await _postGraphQL(query, {'handle': handle, 'first': first});
    final coll = data['data']?['collection'];
    if (coll == null) return [];

    final edges = (coll['products']?['edges'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return edges.map(_mapProductEdge).toList();
  }

  static Product _mapProductEdge(Map<String, dynamic> edge) {
    final node = edge['node'] as Map<String, dynamic>;
    final img = node['featuredImage'] as Map<String, dynamic>?;
    final imageUrl =
        (img?['url'] as String?) ??
        'https://via.placeholder.com/600x600.png?text=ShrimpShop';

    final variantEdges = (node['variants']?['edges'] as List?) ?? [];
    final variants = variantEdges.map<Variant>((e) {
      final vNode = e['node'] as Map<String, dynamic>;
      final gid = (vNode['id'] as String?) ?? '';
      final numeric = gid.isEmpty ? '' : _variantGidToNumeric(gid);

      final priceMap = vNode['price'] as Map<String, dynamic>?;
      final priceStr = (priceMap?['amount'] as String?) ?? '0';
      final price = double.tryParse(priceStr) ?? 0.0;

      final compareMap = vNode['compareAtPrice'] as Map<String, dynamic>?;
      final compareStr = compareMap?['amount'] as String?;
      final compare = compareStr == null ? null : double.tryParse(compareStr);

      return Variant(
        gid: gid,
        title: (vNode['title'] as String?) ?? '',
        price: price,
        numericId: numeric,
        compareAtPrice: compare, // ✅ DAS HIER HINZUFÜGEN
      );
    }).toList();

    return Product(
      gid: (node['id'] as String?) ?? '',
      title: (node['title'] as String?) ?? '',
      handle: (node['handle'] as String?) ?? '',
      imageUrl: imageUrl,
      description: (node['descriptionHtml'] as String?) ?? '',
      variants: variants,
    );
  }
}

/// =======================
/// MainShell
/// =======================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
   final pages = [
  const HomeCategoriesTab(),
  const ProductsTab(),
 // RecipesPage(), // ✅ NEU: Rezepte Tab
  const InfoTab(
    title: 'Story',
    url: 'https://shrimpshop.ch/pages/unsere-story-team',
  ),
  const MoreTab(),
];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kAccent,
        currentIndex: _index,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,

        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
       items: const [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.search),
    label: 'Suche',
  ),
 // BottomNavigationBarItem(    icon: Icon(Icons.restaurant_menu),    label: 'Rezepte',  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.info_outline),
    label: 'Story',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.more_horiz),
    label: 'Mehr',
  ),
],
      ),
    );
  }
}

class HomeCategoriesTab extends StatefulWidget {
  const HomeCategoriesTab({super.key});

  @override
  State<HomeCategoriesTab> createState() => _HomeCategoriesTabState();
  
}

class _HomeCategoriesTabState extends State<HomeCategoriesTab> {

  bool _isLoggedIn = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;

final PageController _productPageController = PageController(
  initialPage: 1,
  viewportFraction: 0.48,
);
  double _productPage = 0.0;


  late Future<List<ShopCollection>> _future;

  late Future<List<Product>> _futureRandomProducts;

  

  Future<List<Product>> _loadRandomProducts() async {
    final list = await ShopifyStorefrontApi.fetchProducts(first: 60);
    list.shuffle(Random()); // ✅ random Reihenfolge
    return list.take(10).toList(); // ✅ nur 10 fürs Carousel
  }


  Future<void> _loadLoginState() async {
    final token = await AuthStorage.readToken();

    if (!mounted) return;

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();

_productPage = 1.0;

    _productPageController.addListener(() {
  if (!_productPageController.hasClients) return;

  setState(() {
    _productPage = _productPageController.page ?? 0.0;
  });
});

    _future = ShopifyStorefrontApi.fetchAppNavigation();
    _futureRandomProducts = _loadRandomProducts(); // ✅ neu
    _loadLoginState();

    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
  if (_pageController.hasClients) {

    _currentPage++;

    if (_currentPage > 3) {
      _currentPage = 0;
    }

    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }
});

  }
@override
void dispose() {
  _carouselTimer?.cancel();
  _pageController.dispose();
  _productPageController.dispose();
  super.dispose();
}



  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartPage()),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
  height: 180,
  width: double.infinity,
  color: Colors.black,
  child: Image.asset(
    'assets/promo_banner.jpg',
    fit: BoxFit.cover,
  ),
),
          
             Positioned.fill(
  child: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Colors.black.withOpacity(0.5),
    Colors.black.withOpacity(0.5),
  ],
),
    ),
  ),
),

              Positioned.fill(
  child: Padding(
   padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
  const Text(
    'Exklusiv für App-Kunden',
    style: TextStyle(
      color: Colors.white70,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
  ),
  const SizedBox(height: 8),
  const Text(
    '15% Rabatt + gratis Versand',
    style: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.05,
    ),
  ),
  const SizedBox(height: 8),
  Text(
    _isLoggedIn
        ? 'Deine Vorteile werden automatisch im Checkout angewendet.'
        : 'Registrieren und Vorteile sichern.',
    style: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.35,
      fontWeight: FontWeight.w500,
    ),
  ),

     
  const SizedBox(height: 12),
  if (!_isLoggedIn)
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFDFC876),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        final auth = ShopifyAuthService(
          shopDomain: ShopifyStorefrontApi.shopDomain,
          storefrontAccessToken:
              ShopifyStorefrontApi.publicStorefrontToken,
        );

        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterPage(auth: auth),
          ),
        );

        if (ok == true && mounted) {
          await _loadLoginState();
        }
      },
      child: const Text(
        'Jetzt registrieren',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    )
  else
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFC876),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Vorteile aktiv',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    ),

    
],
    ),
  ),
),

Positioned(
  top: 12,
  right: 12,
  child: Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Image.asset(
      'assets/logo1.png',
      width: 55,
    ),
  ),
),



              ],
            ),

            
          ),
         
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _TopBar(title: 'HOME', onCart: () => _openCart(context)),
      body: FutureBuilder<List<ShopCollection>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(
              error: snap.error.toString(),
              onRetry: () => setState(() {
                _future = ShopifyStorefrontApi.fetchAppNavigation();
              }),
            );
          }

          final collections = (snap.data ?? []);
          if (collections.isEmpty) {
            return const Center(
              child: Text(
                'Keine Collections gefunden (Menü app-kategorien leer?).',
              ),
            );
          }
return RefreshIndicator(
  onRefresh: () async {
    setState(() {
      _future = ShopifyStorefrontApi.fetchAppNavigation();
      _futureRandomProducts = _loadRandomProducts();
    });
  },
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: 20),
    children: [
 _buildPromoBanner(),


const SizedBox(height: 28),


SizedBox(
  height: 200,
  child: Stack(
    children: [

      PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
       children: const [
  _HomeCarouselImage(
    asset: 'assets/carousel1.jpg',
    url: 'https://shrimpshop.ch/products/ready-to-cook-gluxshrimps-bbq-style-350g?utm_source=copyToPasteBoard&utm_medium=product-links&utm_content=web',
  ),
  _HomeCarouselImage(
    asset: 'assets/carousel2.jpg',
    url: 'https://shrimpshop.ch/products/ready-to-cook-gluxshrimps-bbq-style-350g?utm_source=copyToPasteBoard&utm_medium=product-links&utm_content=web',
  ),
  _HomeCarouselImage(
    asset: 'assets/carousel3.jpg',
    url: 'https://shrimpshop.ch/products/ready-to-cook-gluxshrimps-bbq-style-350g?utm_source=copyToPasteBoard&utm_medium=product-links&utm_content=web',
  ),
    _HomeCarouselImage(
    asset: 'assets/carousel4.jpg',
    url: 'https://shrimpshop.ch/products/ready-to-cook-gluxshrimps-bbq-style-350g?utm_source=copyToPasteBoard&utm_medium=product-links&utm_content=web', // dein gewünschter Link
  ),
],
      ),

      Positioned(
        bottom: 10,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 10 : 8,
              height: _currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFFDFC876)
                    : Colors.white.withOpacity(0.6),
              ),
            );
          }),
        ),
      ),
    ],
  ),
),












/*
Padding(
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const InfoTab(
            title: 'News',
            url: 'https://shrimpshop.ch/blogs/news', // deine News URL
          ),
        ),
      );
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/news_banner.jpg',
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    ),
  ),
),
*/


const SizedBox(height: 24),
           
const Padding(
  padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
  child: Text(
    'Top Picks',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: Colors.white,
    ),
  ),
),
 
SizedBox(
  height: 250,
  child: FutureBuilder<List<Product>>(
    future: _futureRandomProducts,
    builder: (context, psnap) {
      if (!psnap.hasData) return const SizedBox();

      final products = psnap.data!;

      return PageView.builder(
        controller: _productPageController,
        itemCount: products.length,
        padEnds: true,
        itemBuilder: (context, i) {
          final p = products[i];

          final diff = (_productPage - i).abs();
          final scale = (1 - (diff * 0.18)).clamp(0.82, 1.0);
          final verticalPadding = (1 - scale) * 40;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.fromLTRB(6, verticalPadding, 6, 10),
            child: Transform.scale(
              scale: scale,
              child: _ProductCard(
                  p: p,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(p),
                    ),
                  ),
                ),
             ),
          );
        },
      );
    },
  ),
),

const SizedBox(height: 30),


             GridView.builder(
                  shrinkWrap: true,
physics: NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: collections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, i) {
                    final c = collections[i];

                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductListPage(
                            collectionHandle: c.handle,
                            collectionTitle: c.title,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(12),
    topRight: Radius.circular(12),
  ),
  child: Image.network(
    c.imageUrl,
    fit: BoxFit.cover,
    width: double.infinity,
    errorBuilder: (_, _, _) => Container(
      color: const Color(0xFFEFEFEF),
      child: const Icon(Icons.image_not_supported),
    ),
  ),
),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 8,
                            ),
                           decoration: const BoxDecoration(
  color: Color(0xFFDFC876),
),
                            child: Text(
                              c.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                             style: const TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 14,
  color: Color(0xFF2D2D2D),
  letterSpacing: 0.6,
),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                             
                             
const ShrimpDivider(),


const Padding(
  padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
  child: Center(
    child: Text(
      "Seafood News",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color.fromARGB(255, 238, 238, 238),
        letterSpacing: 0.6,
      ),
    ),
  ),
),

Padding(
  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
  child: NewsCarouselWidget(
  key: ValueKey(_futureRandomProducts),
  feedEndpoint: "https://swissprimetaste.ch/api/seafood-news.php",
  onOpen: (url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfoTab(title: 'SeafoodSource', url: url),
      ),
    );
  },
),
),

const SizedBox(height: 110),


            ],
            ),
          );
        },
      ),
    );
  }
}

/// =======================
/// Produktliste / Sort
/// =======================
enum SortMode { newest, az, priceAsc, priceDesc }

class ProductListPage extends StatefulWidget {
  final String collectionHandle;
  final String collectionTitle;

  const ProductListPage({
    super.key,
    required this.collectionHandle,
    required this.collectionTitle,
  });

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late Future<List<Product>> _future;
  String _query = '';
  SortMode _sort = SortMode.newest;

  @override
  void initState() {
    super.initState();
    _future = ShopifyStorefrontApi.fetchProductsByCollection(
      handle: widget.collectionHandle,
      first: 60,
    );
  }

  void _openCart() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CartPage()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _TopBar(
        title: widget.collectionTitle.toUpperCase(),
        onCart: _openCart,
        showBack: true,
      ),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(
              error: snap.error.toString(),
              onRetry: () => setState(() {
                _future = ShopifyStorefrontApi.fetchProductsByCollection(
                  handle: widget.collectionHandle,
                  first: 60,
                );
              }),
            );
          }

          var items = (snap.data ?? []).toList();

          final q = _query.trim().toLowerCase();
          if (q.isNotEmpty) {
            items = items
                .where((p) => p.title.toLowerCase().contains(q))
                .toList();
          }

          switch (_sort) {
            case SortMode.newest:
              break;
            case SortMode.az:
              items.sort(
                (a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              );
              break;
            case SortMode.priceAsc:
              items.sort(
                (a, b) =>
                    a.defaultVariant.price.compareTo(b.defaultVariant.price),
              );
              break;
            case SortMode.priceDesc:
              items.sort(
                (a, b) =>
                    b.defaultVariant.price.compareTo(a.defaultVariant.price),
              );
              break;
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Suche',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<SortMode>(
                    icon: const Icon(Icons.tune),
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: SortMode.newest,
                        child: Text('Neueste'),
                      ),
                      PopupMenuItem(value: SortMode.az, child: Text('A–Z')),
                      PopupMenuItem(
                        value: SortMode.priceAsc,
                        child: Text('Preis ↑'),
                      ),
                      PopupMenuItem(
                        value: SortMode.priceDesc,
                        child: Text('Preis ↓'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return _ProductCard(
                    p: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductDetailPage(p)),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// =======================
/// TAB 2: Products / Search
/// =======================
class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  late Future<List<Product>> _future;
  String _query = '';
  SortMode _sort = SortMode.newest;

  @override
  void initState() {
    super.initState();
    _future = ShopifyStorefrontApi.fetchProducts(first: 60);
  }

  void _openCart() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CartPage()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _TopBar(title: 'SHRIMPS', onCart: _openCart),
      body: FutureBuilder<List<Product>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorBox(
              error: snap.error.toString(),
              onRetry: () => setState(() {
                _future = ShopifyStorefrontApi.fetchProducts(first: 60);
              }),
            );
          }

          var items = (snap.data ?? []).toList();

          final q = _query.trim().toLowerCase();
          if (q.isNotEmpty) {
            items = items
                .where((p) => p.title.toLowerCase().contains(q))
                .toList();
          }

          switch (_sort) {
            case SortMode.newest:
              break;
            case SortMode.az:
              items.sort(
                (a, b) =>
                    a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              );
              break;
            case SortMode.priceAsc:
              items.sort(
                (a, b) =>
                    a.defaultVariant.price.compareTo(b.defaultVariant.price),
              );
              break;
            case SortMode.priceDesc:
              items.sort(
                (a, b) =>
                    b.defaultVariant.price.compareTo(a.defaultVariant.price),
              );
              break;
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(
                () => _future = ShopifyStorefrontApi.fetchProducts(first: 60),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Suche',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<SortMode>(
                      icon: const Icon(Icons.tune),
                      onSelected: (v) => setState(() => _sort = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: SortMode.newest,
                          child: Text('Neueste'),
                        ),
                        PopupMenuItem(value: SortMode.az, child: Text('A–Z')),
                        PopupMenuItem(
                          value: SortMode.priceAsc,
                          child: Text('Preis ↑'),
                        ),
                        PopupMenuItem(
                          value: SortMode.priceDesc,
                          child: Text('Preis ↓'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    return _ProductCard(
                      p: p,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductDetailPage(p)),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// =======================
/// Product Card
/// =======================
class _ProductCard extends StatelessWidget {
  final Product p;
  final VoidCallback onTap;
  const _ProductCard({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: kBg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
               
                child: Stack(
                  children: [
                    Container(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: Image.network(
                          p.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),


Positioned(
  top: 8,
  left: 8,
  child: Consumer<FavoritesModel>(
    builder: (context, favorites, _) {
      final isFav = favorites.isFavorite(p.gid);

      return Material(
        color: Colors.transparent,
       child: GestureDetector(
  onTap: () async {
    final added = await favorites.toggleFavorite(
      FavoriteItem(
  id: p.gid,
  title: p.title,
  imageUrl: p.imageUrl,
  priceText: formatCHF(p.defaultVariant.price),
  subtitle: p.defaultVariant.title,
  variantGid: p.defaultVariant.gid,
),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Zu Favoriten hinzugefügt'
                : 'Aus Favoriten entfernt',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  },
  child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.72),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withOpacity(0.18),
      ),
    ),
    child: Icon(
      isFav ? Icons.favorite : Icons.favorite_border,
      color: const Color(0xFFDFC876),
      size: 20,
    ),
  ),
),
      );
    },
  ),
),



                    // ✅ SALE Badge nur wenn compareAtPrice existiert UND höher ist als price
                    Builder(
                      builder: (context) {
                        final v = p.variants.firstWhere(
                          (x) =>
                              x.compareAtPrice != null &&
                              x.compareAtPrice! > x.price,
                          orElse: () => p.defaultVariant,
                        );

                        final hasSale =
                            (v.compareAtPrice != null &&
                            v.compareAtPrice! > v.price);

                        if (!hasSale) return const SizedBox.shrink();

                      return Positioned(
  top: 12,
  right: 8,
  child: Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 9,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFDFC876),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.28),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: const Text(
      'AKTION',
      style: TextStyle(
        color: Color(0xFF2D2D2D),
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        fontSize: 9,
      ),
    ),
  ),
);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Builder(
                    builder: (context) {
                      final v = p.variants.firstWhere(
                        (x) =>
                            x.compareAtPrice != null &&
                            x.compareAtPrice! > x.price,
                        orElse: () => p.defaultVariant,
                      );

                      final hasCompare =
                          (v.compareAtPrice != null &&
                          v.compareAtPrice! > v.price);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasCompare)
                            Text(
                              formatCHF(v.compareAtPrice!),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          Text(
                            formatCHF(v.price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: kAccent,
                            ),
                          ),
                        ],
                      );
                    },
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

/// =======================
/// Produktdetail
/// =======================
class ProductDetailPage extends StatefulWidget {
  final Product p;
  const ProductDetailPage(this.p, {super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Variant _selected;
  OverlayEntry? _checkOverlay;

  @override
  void initState() {
    super.initState();
    _selected = widget.p.defaultVariant;
  }

  void _openCart() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CartPage()),
  );

  void _showTopCheck() {
    _checkOverlay?.remove();
    _checkOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.80),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_checkOverlay!);
    Future.delayed(const Duration(milliseconds: 900), () {
      _checkOverlay?.remove();
      _checkOverlay = null;
    });
  }



void _showAddedPopup() {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.72), // dunkler Hintergrund
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0B0B), // fast schwarz
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDFC876), width: 1.2), // gold
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titel
              const Text(
                "Hinzugefügt ✅",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFDFC876),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Text
              Text(
                widget.p.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              // Variante + Preis (optional, aber nice)
              Text(
                "${_selected.title} • ${formatCHF(_selected.price)}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Weiter shoppen",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDFC876),
                        foregroundColor: const Color(0xFF0B0B0B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openCart(); // du hast _openCart() schon
                      },
                      child: const Text(
                        "Zum Warenkorb",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // kleiner Hinweis
              Text(
                "Tippe außerhalb, um zu schließen",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _addToCart() {
  context.read<CartModel>().add(widget.p, _selected);
  _showTopCheck();
  _showAddedPopup(); // ✅ NEU
}

  @override
  Widget build(BuildContext context) {
    final p = widget.p;

    return Scaffold(
      appBar: _TopBar(title: widget.p.title, onCart: _openCart, showBack: true),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _addToCart,
              child: const Text(
                'IN DEN WARENKORB',
                style: TextStyle(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),

          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    height: 360,
                    width: double.infinity,
                    child: Center(
                      child: Image.network(
                        p.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.image_not_supported, size: 40),
                      ),
                    ),
                  ),
                ),


Positioned(
  top: 16,
  left: 16,
  child: Consumer<FavoritesModel>(
    builder: (context, favorites, _) {
      final isFav = favorites.isFavorite(p.gid);

      return GestureDetector(
        onTap: () async {
          final added = await favorites.toggleFavorite(
            FavoriteItem(
  id: p.gid,
  title: p.title,
  imageUrl: p.imageUrl,
  priceText: formatCHF(_selected.price),
  subtitle: _selected.title,
  variantGid: _selected.gid,
),
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  added
                      ? 'Zu Favoriten hinzugefügt'
                      : 'Aus Favoriten entfernt',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: const Color(0xFFDFC876),
            size: 18,
          ),
        ),
      );
    },
  ),
),
                if (_selected.compareAtPrice != null &&
                    _selected.compareAtPrice! > _selected.price)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFC876),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        "AKTION",
                        style: TextStyle(
                          color: Color(0xFF2D2D2D),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            

            if (p.description.isNotEmpty) ...[
              Html(
                data: sanitizeProductHtml(p.description),
                style: {
                  "*": Style(color: kText),
                  "body": Style(
                    color: kText,
                    fontSize: FontSize(14),
                    lineHeight: LineHeight(1.5),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "p": Style(margin: Margins.only(bottom: 10)),
                  "strong": Style(fontWeight: FontWeight.w700),
                },
              ),
            ],

            const SizedBox(height: 12),

            const SizedBox(height: 10),
            if (p.variants.length > 1) ...[
              const Text('Variante', style: TextStyle(color: kTextMuted)),
              const SizedBox(height: 6),
              DropdownButtonFormField<Variant>(
                initialValue: _selected,
                isExpanded: true,
                items: p.variants
                    .map(
                      (v) => DropdownMenuItem<Variant>(
                        value: v,
                        child: Text(v.title, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selected = v);
                },
              ),
              const SizedBox(height: 12),
            ],
            Builder(
              builder: (context) {
                final hasCompare =
                    _selected.compareAtPrice != null &&
                    _selected.compareAtPrice! > _selected.price;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasCompare)
                      Text(
                        formatCHF(_selected.compareAtPrice!),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      formatCHF(_selected.price),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: kAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// Cart Page + Checkout WebView
/// =======================
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  DateTime? _deliveryDate;
  Map<String, dynamic>? _defaultAddress;
  bool _addressLoading = true;


@override
void initState() {
  super.initState();
  _loadDefaultAddress();
}
Future<void> _loadDefaultAddress() async {
  try {
    final token = await AuthStorage.readToken();

    if (token == null || token.isEmpty) {
      setState(() {
        _defaultAddress = null;
        _addressLoading = false;
      });
      return;
    }

    final auth = ShopifyAuthService(
      shopDomain: ShopifyStorefrontApi.shopDomain,
      storefrontAccessToken: ShopifyStorefrontApi.publicStorefrontToken,
    );

    final customer = await auth.fetchCustomerWithOrders(token);

    setState(() {
      _defaultAddress = customer?['defaultAddress'] as Map<String, dynamic>?;
      _addressLoading = false;
    });
  } catch (e) {
    setState(() {
      _defaultAddress = null;
      _addressLoading = false;
    });
  }
}
String _formatDefaultAddress(Map<String, dynamic> a) {
  final lines = <String>[];

  final name =
      '${(a['firstName'] ?? '').toString()} ${(a['lastName'] ?? '').toString()}'
          .trim();
  if (name.isNotEmpty) lines.add(name);

  final company = (a['company'] ?? '').toString().trim();
  if (company.isNotEmpty) lines.add(company);

  final address1 = (a['address1'] ?? '').toString().trim();
  if (address1.isNotEmpty) lines.add(address1);

  final address2 = (a['address2'] ?? '').toString().trim();
  if (address2.isNotEmpty) lines.add(address2);

  final zipCity =
      '${(a['zip'] ?? '').toString()} ${(a['city'] ?? '').toString()}'.trim();
  if (zipCity.isNotEmpty) lines.add(zipCity);

  final country = (a['country'] ?? '').toString().trim();
  if (country.isNotEmpty) lines.add(country);

  return lines.join('\n');
}

String _fmtDE(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd.$mm.${d.year}'; // dd.mm.yyyy
}




  // =========================
  // Shopify-Lieferdatum-Regeln
  // =========================

  // Feiertage (ISO) wie in deinem Shopify Script
  final Set<String> _swissHolidays = {
    "2026-01-01",
    "2026-01-02",
    "2026-04-03",
    "2026-04-06",
    "2026-05-01",
    "2026-05-14",
    "2026-05-25",
    "2026-08-01",
    "2026-12-25",
    "2026-12-26",
  };

  // Sperrzeitraum: 22.12.2025 bis inkl. 05.01.2026
  final DateTime _blockFrom = DateTime(2025, 12, 22);
  final DateTime _blockTo = DateTime(2026, 1, 5);

  // ISO Format: YYYY-MM-DD (für Feiertagsvergleich + Shopify Attribute)
  String _fmtIso(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

String _fmtDDMMYYYY(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString();
  return '$dd.$mm.$yyyy';
}

String _fmtNiceDE(DateTime d) {
  return DateFormat('EEEE, d. MMM', 'de_CH').format(d);
}

String _buildCheckoutNote() {
  const zeit = "09:00 - 12:00";

  if (_deliveryDate == null) {
    return "Lieferung: Folgetag bis 12:00\nZeitfenster: $zeit";
  }

  final iso = _fmtDDMMYYYY(_deliveryDate!); // nutzt deine vorhandene _fmtIso()
  return "Lieferdatum: $iso \nZeitfenster: $zeit";
}

// ==============================
// 14:00 Cutoff Logik (morgen / übermorgen)
// ==============================

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _computeMinDate() {
  final now = DateTime.now();
  final today = _dateOnly(now);

  final isAfterCutoff =
      (now.hour > 14) || (now.hour == 14 && now.minute >= 0);

  final addDays = isAfterCutoff ? 2 : 1;

  return today.add(Duration(days: addDays));
}

DateTime _nextAllowedDate(DateTime start) {
  var d = _dateOnly(start);

  while (_isBlocked(d)) {
    d = d.add(const Duration(days: 1));
  }

  return d;
}



  bool _isBlocked(DateTime date) {
    // Uhrzeit raus (nur Datum vergleichen)
    final d = DateTime(date.year, date.month, date.day);

    // 1) Komplett sperren: 22.12.2025 bis inkl. 05.01.2026
    final inBlockedRange = !d.isBefore(_blockFrom) && !d.isAfter(_blockTo);
    if (inBlockedRange) return true;

    // 2) Sa/So/Mo sperren -> nur Di–Fr erlaubt
    final weekday = d.weekday; // Mo=1 ... So=7
    final isForbiddenWeekday =
        (weekday == DateTime.monday ||
        weekday == DateTime.saturday ||
        weekday == DateTime.sunday);
    if (isForbiddenWeekday) return true;

    // 3) Feiertage sperren
    final iso = _fmtIso(d);
    if (_swissHolidays.contains(iso)) return true;

    return false;
  }

 Future<void> _pickDeliveryDate() async {
  final first = _computeMinDate();        // ✅ 14:00 Regel
  final last  = DateTime.now().add(const Duration(days: 180));

  final initial = _deliveryDate != null
      ? (_deliveryDate!.isBefore(first)
          ? _nextAllowedDate(first)
          : _deliveryDate!)
      : _nextAllowedDate(first);

  final picked = await showDatePicker(
    context: context,
    locale: const Locale('de', 'CH'),
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    selectableDayPredicate: (d) => !_isBlocked(d),
  );

  if (picked != null) {
    setState(() => _deliveryDate = _dateOnly(picked));
  }
}


  @override
  Widget build(BuildContext context) {
     final cart = context.watch<CartModel>();
      final defaultAddressId =
      _defaultAddress?['id']?.toString();

      final items = cart.items;
    return Scaffold(
      appBar: const _TopBar(title: 'WARENKORB', onCart: null, showBack: true),

   body: SafeArea(
  child: Builder(
    builder: (context) {
      if (cart.items.isEmpty) {
        return const Center(
          child: Text(
            'Dein Warenkorb ist leer.',
            style: TextStyle(
              color: kText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.fromLTRB(
          12, 12, 12,
          12 + MediaQuery.of(context).padding.bottom + 24,
        ),
       
            children: [
              ...cart.items.map((item) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: kBg,
                            child: Image.network(
                              item.product.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.variant.title,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatCHF(item.variant.price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: kAccent,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ✅ Plus/Minus/Anzahl heller
                        Column(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  cart.add(item.product, item.variant),
                              icon: const Icon(Icons.add, color: Colors.white),
                            ),
                            Text(
                              '${item.qty}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  cart.removeOne(item.product, item.variant),
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // ✅ Papierkorb weiss
                        IconButton(
                          onPressed: () =>
                              cart.removeAll(item.product, item.variant),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 14),

             // ✅ Lieferdatum Block (wie Website-Idee)
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Dein Wunschtermin für Deine Lieferung (Di–Fr):',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),


const SizedBox(height: 12),

Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lieferadresse',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),

        if (_addressLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_defaultAddress != null) ...[
          Text(
            _formatDefaultAddress(_defaultAddress!),
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              final auth = ShopifyAuthService(
                shopDomain: ShopifyStorefrontApi.shopDomain,
                storefrontAccessToken:
                    ShopifyStorefrontApi.publicStorefrontToken,
              );

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountPage(auth: auth),
                ),
              );

              if (mounted) {
                _loadDefaultAddress();
              }
            },
            child: const Text(
              'Adresse ändern',
              style: TextStyle(
                color: Color(0xFFDFC876),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ] else ...[
          const Text(
            'Keine Standardadresse hinterlegt.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              final auth = ShopifyAuthService(
                shopDomain: ShopifyStorefrontApi.shopDomain,
                storefrontAccessToken:
                    ShopifyStorefrontApi.publicStorefrontToken,
              );

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountPage(auth: auth),
                ),
              );

              if (mounted) {
                _loadDefaultAddress();
              }
            },
            child: const Text(
              'Adresse hinzufügen',
              style: TextStyle(
                color: Color(0xFFDFC876),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    ),
  ),
),



        const SizedBox(height: 10),

        OutlinedButton(
          onPressed: _pickDeliveryDate,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDFC876)),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _deliveryDate == null ? 'Datum auswählen' : _fmtNiceDE(_deliveryDate!),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),

        const SizedBox(height: 10),
        const Text(
          'Lasse es leer um Deine Lieferung am Folgetag bis 12 Uhr zu erhalten.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        const Text(
          'Persönliches Lieferzeitfenster:\n09:00 – 12:00',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      ],
    ),
  ),
),

              const SizedBox(height: 12),

              // Zwischensumme
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Zwischensumme',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        formatCHF(cart.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: kAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ KASSE Button: hell + Schrift dunkelgrau
              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 240, 240, 240),
                    foregroundColor: const Color(0xFF444444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),




        onPressed: () async {
  try {
    final customerToken = await AuthStorage.readToken();

    final note = _deliveryDate != null
        ? 'Lieferdatum: ${_fmtDDMMYYYY(_deliveryDate!)}\nZeitfenster: 09:00 - 12:00'
        : 'Lieferung: Folgetag bis 12:00\nZeitfenster: 09:00 - 12:00';

    final checkoutUrl = await ShopifyStorefrontApi.createCartAndGetCheckoutUrl(
      items: cart.items,
      customerAccessToken: customerToken,
      note: note,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutWebViewPage(url: checkoutUrl),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Checkout konnte nicht geöffnet werden: ${e.toString().replaceFirst('Exception: ', '')}',
        ),
      ),
    );
  }
},



                  child: const Text(
                    'KASSE',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ Warenkorb leeren: gold
              TextButton(
                onPressed: cart.clear,
                child: const Text(
                  'Warenkorb leeren',
                  style: TextStyle(
                    color: Color(0xFFDFC876),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    )
  );
  }
}

class CheckoutWebViewPage extends StatefulWidget {
  final String url;
  const CheckoutWebViewPage({super.key, required this.url});

  @override
  State<CheckoutWebViewPage> createState() => _CheckoutWebViewPageState();
}

class _CheckoutWebViewPageState extends State<CheckoutWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onProgress: (p) => setState(() => _progress = p)),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _TopBar(title: 'CHECKOUT', onCart: null, showBack: true),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

/// =======================
/// TAB 3: About Us WebView
/// =======================
class InfoTab extends StatefulWidget {
  final String title;
  final String url;
  const InfoTab({super.key, required this.title, required this.url});

  @override
  State<InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<InfoTab> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onProgress: (p) => setState(() => _progress = p)),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _TopBar(title: widget.title.toUpperCase(), onCart: null),
      body: Column(
        children: [
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

/// =======================
/// TAB 4: More
/// =======================
class MoreTab extends StatefulWidget {
  const MoreTab({super.key});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  Map<String, dynamic>? _customer;
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

Future<void> _loadCustomer() async {
  final token = await AuthStorage.readToken();

  if (token == null || token.isEmpty) {
    setState(() {
      _customer = null;
      _loggedIn = false;
      _loading = false;
    });
    return;
  }

  try {
    final auth = ShopifyAuthService(
      shopDomain: ShopifyStorefrontApi.shopDomain,
      storefrontAccessToken: ShopifyStorefrontApi.publicStorefrontToken,
    );

final customer = await auth.fetchCustomer(token);

if (customer == null) {
  await AuthStorage.clearToken();

  setState(() {
    _customer = null;
    _loggedIn = false;
    _loading = false;
  });
  return;
}

setState(() {
  _customer = customer;
  _loggedIn = true;
  _loading = false;
});
} catch (e) {
  await AuthStorage.clearToken();

  setState(() {
    _customer = null;
    _loggedIn = false;
    _loading = false;
  });
}
}

Future<void> _logout() async {
  await AuthStorage.clearToken();

  if (!mounted) return;

  setState(() {
    _customer = null;
    _loggedIn = false;
  });

   _loadCustomer();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Du bist ausgeloggt')),
  );
}

List<Product>? _allProductsCache;

Future<List<Product>> _loadAllProductsOnce() async {
  if (_allProductsCache != null) return _allProductsCache!;
  _allProductsCache = await ShopifyStorefrontApi.fetchProducts(first: 250);
  return _allProductsCache!;
}

Future<Product?> _findProductByGid(String gid) async {
  final products = await _loadAllProductsOnce();

  for (final p in products) {
    if (p.gid == gid) return p;
  }

  return null;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _TopBar(title: 'MORE', onCart: null),
      body: ListView(
        children: [
      
if (_customer != null) ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
    child: Text(
      "Hi, ${_customer!['firstName']}",
      style: const TextStyle(
  color: Color(0xFFDFC876), // dein Gold
  fontSize: 24,
  fontWeight: FontWeight.w900,
  letterSpacing: 0.5,
),
    ),
  ),
],


       if (_loading)
      const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      )
    else if (_customer != null)
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white10,
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_customer!['firstName'] ?? ''} ${_customer!['lastName'] ?? ''}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _customer!['email'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      )
   else
  const SizedBox.shrink(),
      
      
      ListTile(
  leading: const Icon(Icons.info_outline, color: Colors.white),
  
  title: const Text(
    'Impressum',
    style: TextStyle(color: Colors.white),
  ),
  trailing: const Icon(
    Icons.chevron_right,
    color: Colors.white54,
  ),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const InfoTab(
        title: 'Impressum',
        url: 'https://shrimpshop.ch/policies/legal-notice',
      ),
    ),
  ),
),



      ListTile(
  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
  title: const Text(
    'Datenschutz',
    style: TextStyle(color: Colors.white),
  ),
  trailing: const Icon(
    Icons.chevron_right,
    color: Colors.white54,
  ),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const InfoTab(
        title: 'Datenschutz',
        url: 'https://shrimpshop.ch/policies/privacy-policy',
      ),
    ),
  ),
),
        
        const Divider(),

Consumer<FavoritesModel>(
  builder: (context, favorites, _) {
    return ListTile(
      leading: const Icon(Icons.favorite_border, color: Colors.white),
      title: const Text(
        'Meine Favoriten',
        style: TextStyle(color: Colors.white),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (favorites.count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDFC876),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                favorites.count.toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FavoritesPage(
              onOpenProduct: (item) async {
                final product = await _findProductByGid(item.id);

                if (!mounted) return;

                if (product == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produkt konnte nicht gefunden werden.'),
                    ),
                  );
                  return;
                }

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product),
                  ),
                );
              },
              onAddToCart: (item) async {
                final product = await _findProductByGid(item.id);

                if (!mounted) return;

                if (product == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Produkt konnte nicht gefunden werden.'),
                    ),
                  );
                  return;
                }

                Variant variant = product.defaultVariant;

                final wantedVariantGid = item.variantGid;
                if (wantedVariantGid != null && wantedVariantGid.isNotEmpty) {
                  for (final v in product.variants) {
                    if (v.gid == wantedVariantGid) {
                      variant = v;
                      break;
                    }
                  }
                }

                context.read<CartModel>().add(product, variant);

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    duration: const Duration(milliseconds: 900),
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF111111),
    margin: const EdgeInsets.only(bottom: 90, left: 24, right: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0xFFDFC876)),
    ),
    content: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          color: Color(0xFFDFC876),
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          'Zum Warenkorb hinzugefügt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  ),
);
              },
            ),
          ),
        );
      },
    );
  },
),

if (_loggedIn) ...[
  ListTile(
    leading: const Icon(Icons.person),
    iconColor: Colors.white,
    textColor: Colors.white,
    title: const Text(
      'Mein Konto',
      style: TextStyle(color: Colors.white),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: Colors.white54,
    ),
    onTap: () {
      final auth = ShopifyAuthService(
        shopDomain: ShopifyStorefrontApi.shopDomain,
        storefrontAccessToken: ShopifyStorefrontApi.publicStorefrontToken,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountPage(auth: auth),
        ),
      );
    },
  ),




  ListTile(
    leading: const Icon(Icons.logout),
    iconColor: Colors.white,
    textColor: Colors.white,
    title: const Text(
      'Ausloggen',
      style: TextStyle(color: Colors.white),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: Colors.white54,
    ),
    onTap: _logout,
  ),
] else ...[

  /// LOGIN
  ListTile(
    leading: const Icon(Icons.login),
    iconColor: Colors.white,
    textColor: Colors.white,
    title: const Text(
      'Login',
      style: TextStyle(color: Colors.white),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: Colors.white54,
    ),
    onTap: () async {

      final auth = ShopifyAuthService(
        shopDomain: ShopifyStorefrontApi.shopDomain,
        storefrontAccessToken: ShopifyStorefrontApi.publicStorefrontToken,
      );

      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(auth: auth),
        ),
      );

    if (ok == true && context.mounted) {
  _loadCustomer();
}

    },
  ),

  /// REGISTER
  ListTile(
    leading: const Icon(Icons.person_outline),
    iconColor: Colors.white,
    textColor: Colors.white,
    title: const Text(
      'Konto erstellen',
      style: TextStyle(color: Colors.white),
    ),
    trailing: const Icon(
      Icons.chevron_right,
      color: Colors.white54,
    ),
    onTap: () async {

      final auth = ShopifyAuthService(
        shopDomain: ShopifyStorefrontApi.shopDomain,
        storefrontAccessToken: ShopifyStorefrontApi.publicStorefrontToken,
      );

      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterPage(auth: auth),
        ),
      );

      if (ok == true) {
        _loadCustomer();
      }

    },
  ),

]
        
        
        
        
        
        ],

      ),
    );
  }
}

/// =======================
/// UI: Topbar
/// =======================
class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onCart;
  final bool showBack;

  const _TopBar({
    required this.title,
    required this.onCart,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),

      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
          color: Color.fromARGB(255, 11, 11, 11),
        ),
      ),

   actions: [
  if (onCart != null)
    Consumer<CartModel>(
      builder: (context, cart, _) => IconButton(
        onPressed: onCart,
        icon: _CartIconWithBadge(count: cart.totalQty),
      ),
    ),
  const SizedBox(width: 12),
],
    );
  }
}

class _CartIconWithBadge extends StatefulWidget {
  final int count;
  const _CartIconWithBadge({required this.count});

  @override
  State<_CartIconWithBadge> createState() => _CartIconWithBadgeState();
}

class _CartIconWithBadgeState extends State<_CartIconWithBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.count;

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant _CartIconWithBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Pulse nur wenn count größer wird (also beim Hinzufügen)
    if (widget.count > _lastCount) {
      _c.forward(from: 0);
    }
    _lastCount = widget.count;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.shopping_cart_outlined,
          size: 30,
          color: Colors.black,
        ),

        if (widget.count > 0)
          Positioned(
            right: -10,
            top: -10,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFC876), // Gold
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${widget.count}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}


class ShrimpDivider extends StatelessWidget {
  const ShrimpDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Color(0xFFDFC876),
                Colors.transparent,
              ],
            ),
          ),
        ),
       ],
    );
  }
}


class _ErrorBox extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBox({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 10),
            Text('Fehler beim Laden:\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Nochmal versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCarouselImage extends StatelessWidget {
  final String asset;
  final String url;

  const _HomeCarouselImage({
    required this.asset,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InfoTab(title: 'ShrimpShop', url: url),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
         child: AspectRatio(
  aspectRatio: 16 / 9,
  child: Stack(
    children: [

      Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        alignment: Alignment.center,
      ),

     Positioned(
  top: 12,
  right: 12,
  child: Container(
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Image.asset(
      "assets/logo1.png",
      width: 50,
    ),
  ),
),

    ],
  ),
),
        ),
      ),
    );
  }
}
/// =======================
/// Seafood News Carousel (5 Items)
/// =======================
class NewsItem {
  final String title;
  final String imageUrl;
  final String url;
  final String? date; // optional

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.url,
    this.date,
  });

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        title: (j['title'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        date: j['date']?.toString(),
      );
}

class NewsCarouselWidget extends StatefulWidget {
  final void Function(String url) onOpen;

  /// ✅ Hier kommt später DEIN Proxy rein (empfohlen)
  /// Beispiel-Format: JSON Array mit 5 Items:
  /// [
  ///  {"title":"...", "imageUrl":"...", "url":"...", "date":"2026-03-02"},
  ///  ...
  /// ]
  final String? feedEndpoint;

  const NewsCarouselWidget({
    super.key,
    required this.onOpen,
    this.feedEndpoint,
  });

  @override
  State<NewsCarouselWidget> createState() => _NewsCarouselWidgetState();
}

class _NewsCarouselWidgetState extends State<NewsCarouselWidget> {
  late final PageController _pc;
  int _page = 0;

  late Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.92);
    _future = _loadNews();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<List<NewsItem>> _loadNews() async {
    // ✅ 1) Wenn du einen Endpoint setzt, wird von dort geladen
    if (widget.feedEndpoint != null && widget.feedEndpoint!.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(widget.feedEndpoint!.trim());
        final res = await http.get(uri);

        if (res.statusCode >= 200 && res.statusCode < 300) {
          final data = jsonDecode(res.body);
          if (data is List) {
            final items = data
                .whereType<Map<String, dynamic>>()
                .map(NewsItem.fromJson)
                .where((x) =>
                    x.title.isNotEmpty && x.url.isNotEmpty && x.imageUrl.isNotEmpty)
                .toList();

            if (items.isNotEmpty) {
              return items.take(5).toList();
            }
          }
        }
      } catch (_) {
        // ignore -> fallback
      }
    }

    // ✅ 2) Fallback (damit UI sofort funktioniert)
    return [
      NewsItem(
        title: "SeafoodSource News (Demo) – Item 1",
        imageUrl: "https://via.placeholder.com/1200x700.png?text=Seafood+News+1",
        url: "https://www.seafoodsource.com/news",
        date: "Demo",
      ),
      NewsItem(
        title: "SeafoodSource News (Demo) – Item 2",
        imageUrl: "https://via.placeholder.com/1200x700.png?text=Seafood+News+2",
        url: "https://www.seafoodsource.com/news",
        date: "Demo",
      ),
      NewsItem(
        title: "SeafoodSource News (Demo) – Item 3",
        imageUrl: "https://via.placeholder.com/1200x700.png?text=Seafood+News+3",
        url: "https://www.seafoodsource.com/news",
        date: "Demo",
      ),
      NewsItem(
        title: "SeafoodSource News (Demo) – Item 4",
        imageUrl: "https://via.placeholder.com/1200x700.png?text=Seafood+News+4",
        url: "https://www.seafoodsource.com/news",
        date: "Demo",
      ),
      NewsItem(
        title: "SeafoodSource News (Demo) – Item 5",
        imageUrl: "https://via.placeholder.com/1200x700.png?text=Seafood+News+5",
        url: "https://www.seafoodsource.com/news",
        date: "Demo",
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snap.data!;
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 210,
              child: PageView.builder(
                controller: _pc,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final it = items[i];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      onTap: () => widget.onOpen(it.url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                          Image.network(
  it.imageUrl,
  fit: BoxFit.fitWidth,
  width: double.infinity,

  // 🔄 Ladeanzeige
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return const Center(
      child: CircularProgressIndicator(),
    );
  },

  // ❌ Falls Bild nicht lädt → Fallback
  errorBuilder: (_, __, ___) {
    return Image.asset(
      "assets/news_banner.jpg", // dein Fallback Bild
      fit: BoxFit.cover,
    );
  },
),

                            // dunkler Verlauf unten für Lesbarkeit
                           Positioned(
  left: 12,
  right: 12,
  bottom: 12,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.65),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        if ((it.date ?? '').trim().isNotEmpty)
          Text(
            it.date!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

        const SizedBox(height: 4),

        Text(
          it.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    ),
  ),
),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Punkte
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 10 : 8,
                  height: active ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? const Color(0xFFDFC876) : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}