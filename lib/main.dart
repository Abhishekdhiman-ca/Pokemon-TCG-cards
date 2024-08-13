import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;

void main() {
  runApp(SplashScreenApp());
}

class SplashScreenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Cards',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PokemonCardsApp()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background for the splash screen
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: Size(400, 120),
                painter: PokemonLogoPainter(),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PokemonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Pokémon Cards',
        style: TextStyle(
          fontSize: 50, // Adjusted size to fit in a single line
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..shader = ui.Gradient.linear(
              Offset(0, 0),
              Offset(size.width, size.height),
              [
                Colors.yellow,
                Colors.orange,
              ],
            )
            ..style = PaintingStyle.fill,
          shadows: [
            Shadow(
              blurRadius: 3.0,
              color: Colors.blue,
              offset: Offset(3.0, 3.0),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    textPainter.paint(canvas, Offset(0, size.height / 3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class PokemonCardsApp extends StatefulWidget {
  @override
  _PokemonCardsAppState createState() => _PokemonCardsAppState();
}

class _PokemonCardsAppState extends State<PokemonCardsApp> {
  late Future<List<PokemonCard>> futureCards;
  String searchTerm = '';
  String sortBy = 'name';
  String filterByType = '';
  int minHP = 0;
  int maxHP = 500;
  List<PokemonCard> favoriteCards = [];
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    futureCards = fetchPokemonCards();
  }

  Future<List<PokemonCard>> fetchPokemonCards() async {
    String url;

    if (searchTerm.isEmpty && filterByType.isEmpty) {
      url = 'https://api.pokemontcg.io/v2/cards';
    } else if (searchTerm.isNotEmpty) {
      url = 'https://api.pokemontcg.io/v2/cards?q=name:$searchTerm';
    } else {
      url = 'https://api.pokemontcg.io/v2/cards?q=types:$filterByType';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final cardsData = jsonData['data'] as List;
        return cardsData
            .map((card) => PokemonCard.fromJson(card))
            .where((card) {
          int hp = int.tryParse(card.hp ?? '0') ?? 0;
          return hp >= minHP && hp <= maxHP;
        })
            .toList();
      } else {
        throw Exception('Failed to load Pokémon cards. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Pokémon cards. Error: $e');
    }
  }

  void searchCards(String term) {
    setState(() {
      searchTerm = term;
      futureCards = fetchPokemonCards();
    });
  }

  void sortCards(String sortKey) {
    setState(() {
      sortBy = sortKey;
      futureCards = futureCards.then((cards) {
        cards.sort((a, b) {
          if (sortKey == 'name') {
            return a.name.compareTo(b.name);
          } else if (sortKey == 'hp') {
            return (int.tryParse(a.hp ?? '0') ?? 0).compareTo(int.tryParse(b.hp ?? '0') ?? 0);
          } else if (sortKey == 'type') {
            return a.types?.first.compareTo(b.types?.first ?? '') ?? 0;
          }
          return 0;
        });
        return cards;
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sorted by $sortKey')),
    );
  }

  void filterCards(String type, int minHP, int maxHP) {
    setState(() {
      filterByType = type;
      this.minHP = minHP;
      this.maxHP = maxHP;
      futureCards = fetchPokemonCards();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtered by $type type with HP range $minHP-$maxHP')),
    );
  }

  void toggleFavorite(PokemonCard card) {
    setState(() {
      card.isFavorite = !card.isFavorite;
      if (card.isFavorite) {
        favoriteCards.add(card);
      } else {
        favoriteCards.remove(card);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(card.isFavorite ? 'Added to favorites' : 'Removed from favorites')),
    );
  }

  void toggleShowFavorites() {
    setState(() {
      showFavoritesOnly = !showFavoritesOnly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => showFilterDialog(),
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: toggleShowFavorites,
            color: showFavoritesOnly ? Colors.red : Colors.white,
          ),
          PopupMenuButton<String>(
            onSelected: sortCards,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'hp', child: Text('Sort by HP')),
              PopupMenuItem(value: 'type', child: Text('Sort by Type')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Pokémon...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: searchCards,
            ),
          ),
        ),
      ),
      drawer: buildDrawer(),
      body: FutureBuilder<List<PokemonCard>>(
        future: futureCards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 10),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No Pokémon cards found', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final cards = snapshot.data!;
          final displayCards = showFavoritesOnly ? favoriteCards : cards;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 2 / 3,
            ),
            itemCount: displayCards.length,
            itemBuilder: (context, index) {
              final card = displayCards[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Blur the background
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                          Container(
                            height: 500,
                            width: 350,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(
                                    card.imageUrl,
                                    height: 250,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.image, size: 250);
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    card.name,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'HP: ${card.hp ?? 'Unknown'}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Supertype: ${card.supertype ?? 'Unknown'}',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(height: 10),
                                  if (card.types?.isNotEmpty ?? false)
                                    Text(
                                      'Types: ${card.types!.join(', ')}',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  SizedBox(height: 10),
                                  if (card.abilities?.isNotEmpty ?? false)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: card.abilities!.map((ability) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            'Ability: ${ability['name']} - ${ability['text']}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  if (card.attacks?.isNotEmpty ?? false)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: card.attacks!.map((attack) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            'Attack: ${attack['name']} - ${attack['text']}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  if (card.weaknesses?.isNotEmpty ?? false)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: card.weaknesses!.map((weakness) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Text(
                                            'Weakness: ${weakness['type']} - ${weakness['value']}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  if (card.attacks?.isNotEmpty ?? false)
                                    Text(
                                      'Retreat Cost: ${card.attacks!.map((a) => a['convertedEnergyCost']).join(', ')}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Center(child: CircularProgressIndicator()),
                                Image.network(
                                  card.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.image, size: 100);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(child: CircularProgressIndicator());
                                  },
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              card.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: Icon(
                            card.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () => toggleFavorite(card),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Drawer buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text(
              'Options',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              setState(() {
                showFavoritesOnly = false;
                filterByType = '';
                futureCards = fetchPokemonCards();
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text('Favorites'),
            onTap: () {
              setState(() {
                showFavoritesOnly = true;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.filter_list),
            title: Text('Filter by Fire Type'),
            onTap: () {
              filterCards('Fire', minHP, maxHP);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Pokémon Cards'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Type'),
                onChanged: (value) {
                  filterByType = value;
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Min HP'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  minHP = int.tryParse(value) ?? 0;
                },
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Max HP'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  maxHP = int.tryParse(value) ?? 500;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                filterCards(filterByType, minHP, maxHP);
                Navigator.of(context).pop();
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: Text('Settings Page Content'),
      ),
    );
  }
}

class PokemonCard {
  final String id;
  final String name;
  final String imageUrl;
  final String? supertype;
  final String? hp;
  final List<dynamic>? types;
  final List<dynamic>? abilities;
  final List<dynamic>? weaknesses;
  final List<dynamic>? attacks;
  bool isFavorite = false;

  PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.supertype,
    this.hp,
    this.types,
    this.abilities,
    this.weaknesses,
    this.attacks,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      imageUrl: json['images']['small'] ?? '',
      supertype: json['supertype'],
      hp: json['hp'],
      types: json['types'],
      abilities: json['abilities'],
      weaknesses: json['weaknesses'],
      attacks: json['attacks'],
    );
  }
}
