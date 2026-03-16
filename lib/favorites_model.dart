import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String id;
  final String title;
  final String imageUrl;
  final String priceText;
  final String? subtitle;
  final String? variantGid;

  FavoriteItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.priceText,
    this.subtitle,
    this.variantGid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'priceText': priceText,
      'subtitle': subtitle,
      'variantGid': variantGid,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      priceText: map['priceText']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      variantGid: map['variantGid']?.toString(),
    );
  }
}

class FavoritesModel extends ChangeNotifier {
  static const String _storageKey = 'shrimpshop_favorites_v1';

  final Map<String, FavoriteItem> _items = {};

  List<FavoriteItem> get items => _items.values.toList();

  bool isFavorite(String productId) {
    return _items.containsKey(productId);
  }

  int get count => _items.length;

  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw == null || raw.isEmpty) return;

      final List<dynamic> decoded = jsonDecode(raw);
      _items.clear();

      for (final item in decoded) {
        final fav = FavoriteItem.fromMap(Map<String, dynamic>.from(item));
        _items[fav.id] = fav;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Favorites load error: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _items.values.map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Favorites save error: $e');
    }
  }

  Future<bool> toggleFavorite(FavoriteItem item) async {
    final alreadyFavorite = _items.containsKey(item.id);

    if (alreadyFavorite) {
      _items.remove(item.id);
    } else {
      _items[item.id] = item;
    }

    notifyListeners();
    await _saveFavorites();

    return !alreadyFavorite;
  }

  Future<void> removeById(String productId) async {
    _items.remove(productId);
    notifyListeners();
    await _saveFavorites();
  }

  Future<void> clearAll() async {
    _items.clear();
    notifyListeners();
    await _saveFavorites();
  }
}