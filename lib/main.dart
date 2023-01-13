import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  GlobalKey? historyListKey;
  var history = <WordPair>[];

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>{};
  void toggleFavorites([WordPair? wordpair]) {
    wordpair = wordpair ?? current;
    if (favorites.contains(wordpair)) {
      favorites.remove(wordpair);
    } else {
      favorites.add(wordpair);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                      icon: Icon(Icons.home), label: Text('Home')),
                  NavigationRailDestination(
                      icon: Icon(Icons.favorite), label: Text('Favorites')),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            )
          ],
        ),
      );
    });
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        Expanded(
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400, childAspectRatio: 400 / 80),
            children: [
              for (var word in appState.favorites)
                ListTile(
                    leading: IconButton(
                        onPressed: () {
                          appState.toggleFavorites(word);
                        },
                        icon: Icon(Icons.delete_outline),
                        color: Theme.of(context).primaryColor),
                    title: Text(
                      word.asLowerCase,
                      semanticsLabel: word.asPascalCase,
                    ))
            ],
          ),
        )
      ],
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Text('A random idea:'),
          Expanded(
            flex: 3,
            child: HistroyView(),
          ),
          SizedBox(
            height: 10,
          ),
          BigCard(pair: pair),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                  onPressed: () {
                    appState.toggleFavorites();
                  },
                  icon: Icon(icon),
                  label: Text('Like')),
              SizedBox(
                width: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    appState.getNext();
                    // appState.updateHistory();
                  },
                  child: Text('Next')),
            ],
          ),
          Spacer(
            flex: 2,
          )
        ],
      ),
    );
  }
}

class HistroyView extends StatefulWidget {
  @override
  State<HistroyView> createState() => _HistroyViewState();
}

class _HistroyViewState extends State<HistroyView> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            colors: [Colors.transparent, Colors.black],
            stops: [0.0, 0.5],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: AnimatedList(
            key: _key,
            reverse: true,
            padding: EdgeInsets.only(top: 100),
            initialItemCount: appState.history.length,
            itemBuilder: ((context, index, animation) {
              final wordpair = appState.history[index];
              return SizeTransition(
                  sizeFactor: animation,
                  child: Center(
                      child: TextButton.icon(
                          onPressed: () {
                            appState.toggleFavorites(wordpair);
                          },
                          icon: appState.favorites.contains(wordpair)
                              ? AnimatedAlign(
                                  alignment: Alignment.centerLeft,
                                  duration: const Duration(seconds: 2),
                                  child: Icon(
                                    Icons.favorite,
                                    size: 12,
                                  ))
                              : SizedBox(),
                          label: Text(
                            wordpair.asLowerCase,
                            semanticsLabel: wordpair.asPascalCase,
                          ))));
            })));
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase,
            style: style, semanticsLabel: pair.asPascalCase),
      ),
    );
  }
}
