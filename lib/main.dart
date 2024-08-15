import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(SplashScreenApp());
}

class SplashScreenApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon Shuffle',
      theme: ThemeData(
        primaryColor: Colors.deepPurpleAccent,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(
            fontSize: 36.0,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurpleAccent,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurpleAccent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
    Future.delayed(Duration(seconds: 5), () {
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/splash3.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10.0 * _animation.value,
                    sigmaY: 10.0 * _animation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.1 * _animation.value),
                  ),
                );
              },
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pokémon Shuffle',
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.white,
                          offset: Offset(3.0, 3.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    color: Colors.yellowAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PokemonCardsApp extends StatefulWidget {
  @override
  _PokemonCardsAppState createState() => _PokemonCardsAppState();
}

class _PokemonCardsAppState extends State<PokemonCardsApp> with TickerProviderStateMixin {
  late Future<List<PokemonCard>> futureCards;
  List<PokemonCard> selectedCards = [];
  PokemonCard? winner;
  bool isShuffling = false;
  late AnimationController shuffleController;

  @override
  void initState() {
    super.initState();
    futureCards = fetchPokemonCards();
    shuffleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
  }

  Future<List<PokemonCard>> fetchPokemonCards() async {
    final response = await http.get(Uri.parse('https://api.pokemontcg.io/v2/cards'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final cardsData = jsonData['data'] as List;
      return cardsData.map((card) => PokemonCard.fromJson(card)).toList();
    } else {
      throw Exception('Failed to load Pokémon cards');
    }
  }

  void selectRandomCards(List<PokemonCard> cards) {
    final random = Random();
    selectedCards = [];
    while (selectedCards.length < 5) {
      var randomCard = cards[random.nextInt(cards.length)];
      if (!selectedCards.contains(randomCard)) {
        selectedCards.add(randomCard);
      }
    }
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void startBattleSequence() async {
    HapticFeedback.vibrate();
    setState(() {
      isShuffling = true;
    });

    shuffleController.forward();
    await Future.delayed(Duration(seconds: 3));

    setState(() {
      shuffleController.stop();
      isShuffling = false;
    });

    determineWinner();
  }

  void determineWinner() {
    if (selectedCards.isNotEmpty) {
      winner = selectedCards.reduce((current, next) {
        int currentHp = int.tryParse(current.hp ?? '0') ?? 0;
        int nextHp = int.tryParse(next.hp ?? '0') ?? 0;
        return currentHp > nextHp ? current : next;
      });
    }
    setState(() {});
  }

  void resetGame() {
    setState(() {
      winner = null;
      selectedCards = [];
      futureCards = fetchPokemonCards();
    });
  }

  @override
  void dispose() {
    shuffleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokémon Shuffle'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                futureCards = fetchPokemonCards();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/splash3.jpg',
              fit: BoxFit.cover,
            ),
          ),
          FutureBuilder<List<PokemonCard>>(
            future: futureCards,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No Pokémon cards found'));
              }

              final cards = snapshot.data!;

              return Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () => selectRandomCards(cards),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: Text('Select 5 Random Cards'),
                        ),
                      ),
                      Expanded(
                        child: selectedCards.isNotEmpty
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: selectedCards.map((card) {
                            return Card(
                              elevation: 8,
                              child: ListTile(
                                leading: Image.network(card.imageUrl, width: 50, height: 50),
                                title: Text(
                                  card.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                                subtitle: Text(
                                  'HP: ${card.hp ?? 'Unknown'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )
                            : Center(child: Text('No cards selected')),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: startBattleSequence,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: Text('Start Battle'),
                        ),
                      ),
                    ],
                  ),
                  if (isShuffling)
                    AnimatedShuffleCards(
                      controller: shuffleController,
                      cards: selectedCards,
                    ),
                  if (winner != null && !isShuffling)
                    WinnerDisplay(winner: winner!, resetGame: resetGame),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class AnimatedShuffleCards extends StatelessWidget {
  final AnimationController controller;
  final List<PokemonCard> cards;

  const AnimatedShuffleCards({
    Key? key,
    required this.controller,
    required this.cards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          children: cards.map((card) {
            final random = Random();
            double randomX = random.nextDouble() * MediaQuery.of(context).size.width - 100;
            double randomY = random.nextDouble() * MediaQuery.of(context).size.height - 100;
            return Positioned(
              left: randomX,
              top: randomY,
              child: Transform.scale(
                scale: 1 + 0.5 * sin(controller.value * 2 * pi),
                child: Opacity(
                  opacity: 0.5 + 0.5 * sin(controller.value * 2 * pi),
                  child: SizedBox(
                    width: 150,
                    height: 200,
                    child: Card(
                      elevation: 8,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(card.imageUrl, width: 100, height: 100),
                          SizedBox(height: 10),
                          Text(
                            card.name,
                            style: TextStyle(fontSize: 18, color: Colors.deepPurpleAccent),
                          ),
                          Text('HP: ${card.hp ?? 'Unknown'}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class WinnerDisplay extends StatelessWidget {
  final PokemonCard winner;
  final VoidCallback resetGame;

  const WinnerDisplay({Key? key, required this.winner, required this.resetGame}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellowAccent,
                    blurRadius: 10.0,
                    spreadRadius: 5.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Winner!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Image.network(winner.imageUrl, width: 150, height: 150),
                  Text('${winner.name} with HP: ${winner.hp}', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: resetGame,
                  child: Text('Play Again'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text('Exit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PokemonCard {
  final String id;
  final String name;
  final String imageUrl;
  final String? hp;
  final String? rarity;

  PokemonCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.hp,
    this.rarity,
  });

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      id: json['id'],
      name: json['name'],
      imageUrl: json['images']['small'],
      hp: json['hp'],
      rarity: json['rarity'],
    );
  }
}
