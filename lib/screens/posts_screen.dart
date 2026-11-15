
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/favorites_service.dart';
import 'favorites_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService postService = PostService();
  final FavoritesService favoritesService = FavoritesService();

  late Future<List<Post>> postsFuture;

  @override
  void initState() {
    super.initState();
    postsFuture = postService.getPosts();
  }

  void refreshPosts() {
    setState(() {
      postsFuture = postService.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'My Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FavoritesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text('No posts available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              refreshPosts();
              await postsFuture;
            },
            child: ValueListenableBuilder<Box<Post>>(
              valueListenable:
                  Hive.box<Post>('favoritesBox').listenable(),
              builder: (context, box, child) {
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    final isFavorite =
                        favoritesService.isFavorite(post.id);

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(post.body),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Post ID: ${post.id}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await favoritesService
                                        .toggleFavorite(post);
                                  },
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: isFavorite
                                        ? Colors.amber
                                        : Colors.grey,
                                  ),
                                  tooltip: isFavorite
                                      ? 'Remove from favorites'
                                      : 'Add to favorites',
                                ),
                              ],
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
        },
      ),
    );
  }
}
