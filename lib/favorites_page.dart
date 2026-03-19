import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorites_model.dart';

class FavoritesPage extends StatelessWidget {
  final Future<void> Function(FavoriteItem item)? onOpenProduct;
  final Future<void> Function(FavoriteItem item)? onAddToCart;
  final VoidCallback? onOpenCart;
    final void Function(int index)? onNavigateTab;

  const FavoritesPage({
  super.key,
  this.onOpenProduct,
  this.onAddToCart,
  this.onOpenCart,
  this.onNavigateTab,
});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesModel>();
    final items = favorites.items;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        title: const Text('Meine Favoriten'),
        actions: [
          IconButton(
            tooltip: 'Warenkorb',
            onPressed: onOpenCart,
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyFavoritesView()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  color: const Color(0xFF111111),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onOpenProduct == null
                        ? null
                        : () async {
                            await onOpenProduct!(item);
                          },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 84,
                                      height: 84,
                                      color: Colors.grey.shade900,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 84,
                                    height: 84,
                                    color: Colors.grey.shade900,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  item.priceText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDFC876),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Color(0xFFDFC876),
                                        ),
                                      ),
                                      onPressed: onOpenProduct == null
                                          ? null
                                          : () async {
                                              await onOpenProduct!(item);
                                            },
                                      child: const Text('Ansehen'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFDFC876),
                                        foregroundColor: Colors.black,
                                      ),
                                      onPressed: onAddToCart == null
                                          ? null
                                          : () async {
                                              await onAddToCart!(item);
                                            },
                                      child: const Text('In den Warenkorb'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Entfernen',
                            onPressed: () async {
                              await context
                                  .read<FavoritesModel>()
                                  .removeById(item.id);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Aus Favoriten entfernt'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.favorite,
                              color: Color(0xFFDFC876),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    bottomNavigationBar: BottomNavigationBar(
  backgroundColor: const Color(0xFFDBDBDB),
  currentIndex: 3,
  selectedItemColor: Colors.black,
  unselectedItemColor: Colors.black54,
  type: BottomNavigationBarType.fixed,
  onTap: (index) {
    if (index == 3) {
      Navigator.pop(context);
      return;
    }

    if (onNavigateTab != null) {
      Navigator.pop(context);
      onNavigateTab!(index);
    }
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.info_outline),
      label: 'Story',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search),
      label: 'Suche',
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

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.favorite_border,
              size: 54,
              color: Color(0xFFDFC876),
            ),
            SizedBox(height: 14),
            Text(
              'Noch keine Favoriten gespeichert',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tippe auf das Herz bei einem Produkt, um es hier zu speichern.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}