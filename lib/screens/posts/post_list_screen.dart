// This lists all the posts from different users.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import 'post_form_screen.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PostsProvider>().fetchPosts(refresh: true);
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        context.read<PostsProvider>().fetchPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = context.watch<PostsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          if (context.watch<AuthProvider>().isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthProvider>().signOut(),
            )
          else ...[
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Register'),
            ),
          ],
        ],
      ),
      body: ListView.builder(
        controller: scrollController,
        itemCount: postsProvider.posts.length + 1,
        itemBuilder: (context, index) {
          if (index == postsProvider.posts.length) {
            return postsProvider.hasMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final post = postsProvider.posts[index];
          final images = post['post_images'] as List;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.network(
                            images[i]['url'],
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      post['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      post['body'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: context.watch<AuthProvider>().isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PostFormScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
