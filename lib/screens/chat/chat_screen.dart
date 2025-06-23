import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/services/api_service/users_service.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/widgets/navbar.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with AutomaticKeepAliveClientMixin {
  late TextEditingController _searchController;
  late Future<List<Map<String, dynamic>>> _futureUsers;
  late Storage _storage;
  final Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _storage = Storage();
    _futureUsers = getUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> getUsers({String query = ''}) async {
    try {
      final accessToken = await _storage.getAccessTokenAsync();
      final response = await dio.get(
        '${constants.apiEndpoint}/users/search',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200 && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        return [];
      }
    } catch (e) {
      myLogger.e('Error fetching users: $e');
      return [];
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _futureUsers = getUsers(query: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = ref.watch(themeNotifierProvider);

    return Scaffold(
      backgroundColor: theme.secondaryBackground.withValues(alpha: 0),
      appBar: AppBar(title: const Text('Chat Screen'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.primaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                hintText: 'Search',
                hintStyle: TextStyle(color: theme.primaryText.withAlpha(128), fontSize: 16),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                prefixIcon: Icon(Icons.search_rounded, color: theme.primaryText.withAlpha(128)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futureUsers,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error fetching users', style: TextStyle(color: Colors.red)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }

                  final users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final avatarUrl = '${constants.bucketEndpoint}/${user['avatar_url'] ?? 'defaults/default-avatar.jpg'}';

                      return ListTile(
                        tileColor: theme.secondaryBackground,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: CircleAvatar(radius: 24, backgroundColor: theme.primaryBackground, backgroundImage: ResizeImage(NetworkImage(avatarUrl), height: 132, width: 132)),
                        title: Text(user['username'] ?? 'Unknown', style: TextStyle(fontSize: 16, color: theme.primaryText)),
                        trailing: user['is_following'] == true
                            ? ElevatedButton(
                                onPressed: () async {
                                  myLogger.d('user.id: $user');
                                  final UserService usersService = UserService();
                                  await usersService.fetchUnfollow(followingId: user['id']);
                                  if (!context.mounted) return;
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black38,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Followed'),
                              )
                            : ElevatedButton(
                                onPressed: () async {
                                  myLogger.d('user.id: $user');
                                  final UserService usersService = UserService();
                                  await usersService.fetchFollow(followingId: user['id']);
                                  if (!context.mounted) return;
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black38,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Follow'),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
