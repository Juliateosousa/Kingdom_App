import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Shared button style for KingdomSchool
Widget ksOutlinedButton(
  BuildContext context,
  String text,
  VoidCallback onPressed,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        minimumSize: const Size(double.infinity, 60),
        foregroundColor: Colors.black, // text/icon color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.black54,
            width: 1,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black,
        ),
      ),
    ),
  );
}

class KingdomSchoolPage extends StatelessWidget {
  const KingdomSchoolPage({super.key});

  void openCategory(BuildContext context, String categoryName) {
    if (categoryName == "Bar") {
      // 👉 Go to the subcategories page for drinks
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DrinksSubcategoryPage(),
        ),
      );
    } else {
      // 👉 All other categories still go straight to the playlist
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistPage(categoryName: categoryName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KingdomSchool"),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.favorite, color: Colors.redAccent, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            buildButton(context, "Important"),
            buildButton(context, "Bar"),
            buildButton(context, "Cleaning"),
            buildButton(context, "Menu"),
            buildButton(context, "Costumer Service"),
            buildButton(context, "Host"),
            buildButton(context, "Promotions and Discounts"),
          ],
        ),
      ),
    );
  }

  // Uses shared outlined button style
  Widget buildButton(BuildContext context, String text) {
    return ksOutlinedButton(
      context,
      text,
      () => openCategory(context, text),
    );
  }
}

class DrinksSubcategoryPage extends StatelessWidget {
  const DrinksSubcategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drinks")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildButton(context, "Alcoholic Beverages"),
            _buildButton(context, "Non-Alcoholic Beverages"),
            _buildButton(context, "Preparations"),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return ksOutlinedButton(
      context,
      text,
      () {
        if (text == "Non-Alcoholic Beverages") {
          // 👇 this one has sub-subcategories
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DrinksNonAlcoholicSubcategoryPage(),
            ),
          );
        } else if (text == "Alcoholic Beverages") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const DrinksAlcoholicSubcategoryPage(),
            ),
          );
        } else {
          // Alcoholic Beverages and Preparations go straight to playlists
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistPage(categoryName: text),
            ),
          );
        }
      },
    );
  }
}

class DrinksAlcoholicSubcategoryPage extends StatelessWidget {
  const DrinksAlcoholicSubcategoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Non-Alcoholic Beverages")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildButton(context, "House Cocktails"),
            _buildButton(context, "Cocktail"),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return ksOutlinedButton(
      context,
      text,
      () {
        // each of these opens its own playlist
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistPage(categoryName: text),
          ),
        );
      },
    );
  }
}

class DrinksNonAlcoholicSubcategoryPage extends StatelessWidget {
  const DrinksNonAlcoholicSubcategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Non-Alcoholic Beverages")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildButton(context, "Juices"),
            _buildButton(context, "Coffee"),
            _buildButton(context, "Mocktails"),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text) {
    return ksOutlinedButton(
      context,
      text,
      () {
        // each of these opens its own playlist
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistPage(categoryName: text),
          ),
        );
      },
    );
  }
}

class VideoItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String thumbnailUrl;

  VideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory VideoItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
    );
  }
}

// =======================
// VIDEO PLAYER PAGE
// =======================

class VideoPlayerPage extends StatefulWidget {
  final List<VideoItem> videos;
  final int initialIndex;

  const VideoPlayerPage({
    super.key,
    required this.videos,
    required this.initialIndex,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final PageController _pageController;
  late final List<GlobalKey<_VideoPageState>> _pageKeys;
  late final int _initialIndex;

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.initialIndex.clamp(0, widget.videos.length - 1);
    _pageController = PageController(initialPage: _initialIndex);

    _pageKeys = List.generate(
      widget.videos.length,
      (_) => GlobalKey<_VideoPageState>(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePageChanged(_initialIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int index) {
    for (var i = 0; i < _pageKeys.length; i++) {
      final state = _pageKeys[i].currentState;
      if (state == null) continue;

      if (i == index) {
        state.play();
      } else {
        state.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.videos.length,
            allowImplicitScrolling: true,
            onPageChanged: _handlePageChanged,
            itemBuilder: (context, index) {
              final video = widget.videos[index];
              return VideoPage(
                key: _pageKeys[index],
                video: video,
              );
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back, size: 28, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================
// SINGLE VIDEO PAGE
// =======================

class VideoPage extends StatefulWidget {
  final VideoItem video;

  const VideoPage({super.key, required this.video});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  VideoPlayerController? _controller;
  bool isLiked = false;
  bool _initTried = false;
  bool showDescription = false;
  bool _showPlayOverlay = false;
  bool _shouldPlayWhenReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));

    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      controller.setLooping(true);

      setState(() {
        _initTried = true;
      });

      if (_shouldPlayWhenReady) {
        controller.play();
        setState(() => _showPlayOverlay = false);
      }

      await _loadFavoriteState();
    } catch (e) {
      setState(() {
        _initTried = true;
      });
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final favDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("favorites")
          .doc(widget.video.id)
          .get();

      if (mounted) {
        setState(() => isLiked = favDoc.exists);
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void play() {
    _shouldPlayWhenReady = true;
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      c.play();
      setState(() => _showPlayOverlay = false);
    }
  }

  void pause() {
    _shouldPlayWhenReady = false;
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      c.pause();
      setState(() => _showPlayOverlay = true);
    }
  }

  Widget _buildBody() {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      if (!_initTried) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return const Center(
        child: Text(
          "Could not load video.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: () => controller.value.isPlaying ? pause() : play(),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("favorites")
        .doc(widget.video.id);

    final newValue = !isLiked;
    setState(() => isLiked = newValue);

    if (newValue) {
      await ref.set({
        "videoId": widget.video.id,
        "title": widget.video.title,
        "description": widget.video.description,
        "category": widget.video.category,
        "videoUrl": widget.video.videoUrl,
        "thumbnailUrl": widget.video.thumbnailUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _buildBody()),

        if (_showPlayOverlay)
          const Center(
            child: Icon(Icons.play_arrow_rounded,
                size: 100, color: Colors.white70),
          ),

        Positioned(
          right: 16,
          bottom: 160,
          child: Column(
            children: [
              IconButton(
                iconSize: 42,
                color: isLiked ? Colors.red : Colors.white,
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                onPressed: _toggleFavorite,
              ),
              const SizedBox(height: 24),
              IconButton(
                iconSize: 40,
                color: Colors.white,
                icon: Icon(
                    showDescription ? Icons.info : Icons.info_outline),
                onPressed: () =>
                    setState(() => showDescription = !showDescription),
              ),
            ],
          ),
        ),

        if (showDescription)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.85),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          widget.video.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => showDescription = false),
                        child: const Text(
                          "Close",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =======================
// PLAYLIST PAGE
// =======================

class PlaylistPage extends StatefulWidget {
  final String categoryName;

  const PlaylistPage({super.key, required this.categoryName});

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  Set<String> favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitialFavorites();
  }

  Future<void> _loadInitialFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("favorites")
        .get();

    setState(() {
      favoriteIds = snap.docs
          .map((d) => (d.data()['videoId'] ?? d.id).toString())
          .toSet();
    });
  }

  Future<void> _toggleFavorite(VideoItem video) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("favorites")
        .doc(video.id);

    final newValue = !favoriteIds.contains(video.id);

    setState(() {
      if (newValue) {
        favoriteIds.add(video.id);
      } else {
        favoriteIds.remove(video.id);
      }
    });

    if (newValue) {
      await ref.set({
        "videoId": video.id,
        "title": video.title,
        "description": video.description,
        "category": video.category,
        "videoUrl": video.videoUrl,
        "thumbnailUrl": video.thumbnailUrl,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("videos")
        .where("category", isEqualTo: widget.categoryName);

    return Scaffold(
      appBar: AppBar(title: Text("Playlist - ${widget.categoryName}")),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final videos =
              docs.map((e) => VideoItem.fromDoc(e)).toList();

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              final isFav = favoriteIds.contains(video.id);

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: video.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            video.thumbnailUrl,
                            width: 80,
                            height: 45,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 45,
                            color: Colors.black12,
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 32,
                            ),
                          ),
                  ),
                  title: Text(video.title),
                  subtitle: Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(video),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerPage(
                          videos: videos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =======================
// FAVORITES PAGE
// =======================

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Favorites")),
        body: const Center(child: Text("You must be logged in.")),
      );
    }

    final favsRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("favorites")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: StreamBuilder<QuerySnapshot>(
        stream: favsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("You have no favorites yet"),
            );
          }

          final videos = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return VideoItem(
              id: data["videoId"],
              title: data["title"],
              description: data["description"],
              category: data["category"],
              videoUrl: data["videoUrl"],
              thumbnailUrl: data["thumbnailUrl"] ?? '',
            );
          }).toList();

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: video.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            video.thumbnailUrl,
                            width: 80,
                            height: 45,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 80,
                            height: 45,
                            color: Colors.black12,
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 32,
                            ),
                          ),
                  ),
                  trailing: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 26,
                  ),
                  title: Text(video.title),
                  subtitle: Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerPage(
                          videos: videos,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
