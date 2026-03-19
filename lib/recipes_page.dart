import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key}); // ✅ wichtig
  @override
  State<RecipesPage> createState() => _RecipesPageState();
}


class _RecipesPageState extends State<RecipesPage> {
  late Future<List<dynamic>> _recipesFuture;

  Future<List<dynamic>> fetchRecipes() async {
    final url = Uri.parse('https://swissprimetaste.ch/recipes/recipes.json');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body);

    // erwartet: { "recipes": [ ... ] }
    return (data['recipes'] as List<dynamic>);
  }

  @override
  void initState() {
    super.initState();
    _recipesFuture = fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
  backgroundColor: Colors.black,
     appBar: AppBar(
  backgroundColor: Colors.black,
  title: const Text(
    'Rezepte',
    style: TextStyle(color: Colors.white),
  ),
),
      body: FutureBuilder<List<dynamic>>(
        future: _recipesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
           return const Center(
  child: CircularProgressIndicator(color: Colors.white),
);
          }
          if (snap.hasError) {
            return Center(
             child: Text(
  'Fehler: ${snap.error}',
  style: const TextStyle(color: Colors.white),
),
            );
          }

          final recipes = snap.data!;

          return ListView.separated(
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = recipes[i] as Map<String, dynamic>;
              final title = (r['title'] ?? '').toString();
              final time = (r['time'] ?? '').toString();
              final diff = (r['difficulty'] ?? '').toString();

              return ListTile(
                title: Text(
  title,
  style: const TextStyle(color: Colors.white),
),
               subtitle: Text(
  '$time • $diff',
  style: const TextStyle(color: Colors.white70),
),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailPage(recipe: r),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final title = (recipe['title'] ?? '').toString();
    final time = (recipe['time'] ?? '').toString();
    final diff = (recipe['difficulty'] ?? '').toString();
    final ingredients = (recipe['ingredients'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final steps = (recipe['steps'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return Scaffold(
      backgroundColor: Colors.black, // ✅ 1) Hintergrund schwarz
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ 2) 20min • easy weiss
          Text(
            '$time • $diff',
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // ✅ 3) Überschrift weiss
          const Text(
            'Zutaten',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          ...ingredients.map(
            (x) => Text(
              '• $x',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),

          // ✅ 3) Überschrift weiss
          const Text(
            'Zubereitung',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          ...steps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${e.key + 1}. ${e.value}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}