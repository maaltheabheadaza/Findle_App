import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage_screen.dart';
import 'create_ad.dart';

class LostAndFoundPage extends StatefulWidget {
  final String? userId;
  const LostAndFoundPage({Key? key, this.userId}) : super(key: key);

  @override
  _LostAndFoundPageState createState() => _LostAndFoundPageState();
}

class _LostAndFoundPageState extends State<LostAndFoundPage> {
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _filteredPosts = [];
  final Map<String, String> _usernames = {};
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedType;
  DateTime? _selectedDate;
  bool _isLoading = true;

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Documents',
    'Personal Items'
  ];
  final List<String> _types = ['Lost', 'Found'];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _searchController.addListener(_filterPosts);
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);

    dynamic response;
    if (widget.userId != null) {
      response = await Supabase.instance.client
          .from('post')
          .select()
          .eq('user_id', widget.userId!)
          .order('created_at', ascending: false);
    } else {
      response = await Supabase.instance.client
          .from('post')
          .select()
          .order('created_at', ascending: false);
    }

    setState(() {
      _posts = List<Map<String, dynamic>>.from(response);
      _filteredPosts = _posts;
      _isLoading = false;
    });

    // Get all unique user IDs from posts
    final userIds = _posts
        .where((post) => post['user_id'] != null)
        .map((post) => post['user_id'])
        .toSet()
        .toList();

    if (userIds.isNotEmpty) {
      try {
        print('Fetching usernames for user IDs: $userIds');
        final usersResponse = await Supabase.instance.client
            .from('users')
            .select('id, username')
            .inFilter('id', userIds);

        print('Users response: $usersResponse');
        
        final users = List<Map<String, dynamic>>.from(usersResponse);
        setState(() {
          for (var user in users) {
            _usernames[user['id']] = user['username'];
          }
        });
        print('Usernames map: $_usernames');
            } catch (e) {
        print('Error fetching usernames: $e');
      }
    }
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPosts = _posts.where((post) {
        final title = (post['title'] ?? '').toString().toLowerCase();
        final desc = (post['description'] ?? '').toString().toLowerCase();
        final category = post['category'] ?? '';
        final type = post['post_type'] ?? '';
        final createdAt = post['created_at'] ?? '';
        bool matches = (title.contains(query) || desc.contains(query));
        if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
          matches = matches && category == _selectedCategory;
        }
        if (_selectedType != null && _selectedType!.isNotEmpty) {
          matches = matches && type == _selectedType;
        }
        if (_selectedDate != null) {
          matches = matches &&
              createdAt.startsWith(
                  _selectedDate!.toIso8601String().substring(0, 10));
        }
        return matches;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPosts);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.maroon,
            onPrimary: AppColors.yellow,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _filterPosts();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedType = null;
      _selectedDate = null;
      _searchController.clear();
      _filteredPosts = _posts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.maroon),
        elevation: 1,
        title: SizedBox(
          width: 300,
          child: Text(
            widget.userId != null ? 'My Posts' : 'Lost & Found Newsfeed',
            style: const TextStyle(
              color: AppColors.maroon,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search and Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search items...',
                          prefixIcon:
                              const Icon(Icons.search, color: AppColors.maroon),
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.gray),
                      onPressed: _clearFilters,
                      tooltip: 'Clear filters',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Category Filter
                    Flexible(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ..._categories.map((cat) => DropdownMenuItem(
                                value: cat,
                                child:
                                    Text(cat, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                          _filterPosts();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Type Filter
                    Flexible(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          filled: true,
                          fillColor: AppColors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ..._types.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value);
                          _filterPosts();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date Filter
                    SizedBox(
                      width: 90,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          side: const BorderSide(color: AppColors.gray),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                        ),
                        icon: const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.maroon),
                        label: Text(
                          _selectedDate == null
                              ? 'Date'
                              : '${_selectedDate!.month}/${_selectedDate!.day}',
                          style: const TextStyle(
                              color: AppColors.maroon, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _pickDate(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredPosts.isEmpty
                          ? const Center(
                              child: Text(
                                'No items found.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.gray,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredPosts.length,
                              itemBuilder: (context, index) {
                                final post = _filteredPosts[index];
                                // Debug print for user_id
                                print(
                                    'post user_id: ${post['user_id']} | current user: ${currentUser?.id}');
                                return Card(
                                  color: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  elevation: 3,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PostDetailScreen(post: post),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Image
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: post['image_url'] != null &&
                                                  post['image_url'] != ''
                                              ? Image.network(
                                                  post['image_url'],
                                                  width: double.infinity,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      Container(
                                                    height: 180,
                                                    color: AppColors.lightGray,
                                                    child: const Icon(Icons.image,
                                                        color: AppColors.gray,
                                                        size: 48),
                                                  ),
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: 180,
                                                  color: AppColors.lightGray,
                                                  child: const Icon(Icons.inventory,
                                                      color: AppColors.maroon,
                                                      size: 48),
                                                ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Title
                                              Text(
                                                post['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: AppColors.maroon,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.person_outline,
                                                    size: 16,
                                                    color: AppColors.gray,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _usernames[post['user_id']] ?? 'Anonymous',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors.gray,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              // Description
                                              Text(
                                                post['description'] ?? '',
                                                style:
                                                    const TextStyle(fontSize: 15),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 10),
                                              // Info row
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            post['post_type'] ==
                                                                    'Lost'
                                                                ? AppColors
                                                                    .paleMaroon
                                                                : AppColors
                                                                    .paleYellow,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                8),
                                                      ),
                                                      child: Text(
                                                        post['post_type'] ?? '',
                                                        style: TextStyle(
                                                          color:
                                                              post['post_type'] ==
                                                                      'Lost'
                                                                  ? AppColors
                                                                      .white
                                                                  : AppColors
                                                                      .maroon,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ConstrainedBox(
                                                      constraints:
                                                          const BoxConstraints(
                                                              maxWidth: 80),
                                                      child: Text(
                                                        post['category'] ?? '',
                                                        style: const TextStyle(
                                                          color: AppColors.gray,
                                                          fontSize: 12,
                                                        ),
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.access_time,
                                                        size: 14,
                                                        color: AppColors.gray),
                                                    Text(
                                                      post['created_at'] != null
                                                          ? post['created_at']
                                                              .toString()
                                                              .substring(0, 10)
                                                          : '',
                                                      style: const TextStyle(
                                                        color: AppColors.gray,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.message,
                                                        color: AppColors.maroon,
                                                        size: 22),
                                                    // Edit/Delete buttons for owner
                                                    if (post['user_id'] ==
                                                        currentUser?.id)
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment.end,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.edit,
                                                                color: AppColors
                                                                    .maroon),
                                                            tooltip: 'Edit',
                                                            onPressed: () async {
                                                              // Replace 'CreateAdScreen' with your actual screen name
                                                              final updated =
                                                                  await Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              CreateAdScreen(
                                                                        post:
                                                                            post, // Pass the post data
                                                                        isEdit: true,
                                                                      ),
                                                                    ),
                                                                  );
                                                              if (updated ==
                                                                  true) {
                                                                _fetchPosts(); // Refresh after editing
                                                              }
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                                Icons.delete,
                                                                color:
                                                                    Colors.red),
                                                            tooltip: 'Delete',
                                                            onPressed: () async {
                                                              final confirm =
                                                                  await showDialog<
                                                                      bool>(
                                                                    context: context,
                                                                    builder:
                                                                        (context) =>
                                                                            AlertDialog(
                                                                      title: const Text(
                                                                          'Delete Post'),
                                                                      content: const Text(
                                                                          'Are you sure you want to delete this post?'),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(
                                                                                  context,
                                                                                  false),
                                                                          child: const Text(
                                                                              'Cancel'),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.pop(
                                                                                  context,
                                                                                  true),
                                                                          child: const Text(
                                                                              'Delete'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                              if (confirm ==
                                                                  true) {
                                                                await Supabase
                                                                    .instance
                                                                    .client
                                                                    .from('post')
                                                                    .delete()
                                                                    .eq(
                                                                        'id',
                                                                        post[
                                                                            'id']);
                                                                _fetchPosts();
                                                              }
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.maroon),
        elevation: 1,
        title: Text(
          post['title'] ?? '',
          style: const TextStyle(
            color: AppColors.maroon,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (post['image_url'] != null && post['image_url'] != '')
              Image.network(
                post['image_url'],
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 300,
                  color: AppColors.lightGray,
                  child: const Icon(Icons.image, color: AppColors.gray, size: 48),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 300,
                color: AppColors.lightGray,
                child: const Icon(Icons.inventory, color: AppColors.maroon, size: 48),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.maroon,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: post['post_type'] == 'Lost'
                              ? AppColors.paleMaroon
                              : AppColors.paleYellow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post['post_type'] ?? '',
                          style: TextStyle(
                            color: post['post_type'] == 'Lost'
                                ? AppColors.white
                                : AppColors.maroon,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        post['category'] ?? '',
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16, color: AppColors.gray),
                      const SizedBox(width: 4),
                      Text(
                        post['created_at'] != null
                            ? post['created_at'].toString().substring(0, 10)
                            : '',
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.maroon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
