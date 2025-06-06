import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'homepage_screen.dart';

class CreateAdScreen extends StatefulWidget {
  final Map<String, dynamic>? post;
  final bool isEdit;
  const CreateAdScreen({Key? key, this.post, this.isEdit = false}) : super(key: key);

  @override
  _CreateAdPageState createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _category;
  String? _postType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
    if (widget.isEdit && widget.post != null) {
      _category = widget.post!['category'];
      _postType = widget.post!['post_type'];
      _titleController.text = widget.post!['title'] ?? '';
      _descController.text = widget.post!['description'] ?? '';
      _existingImageUrl = widget.post!['image_url'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final storageResponse = await Supabase.instance.client.storage
          .from('ad-images')
          .upload(fileName, image);
      if (storageResponse.isEmpty) return null;
      final publicUrl = Supabase.instance.client.storage
          .from('ad-images')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    String? imageUrl = _existingImageUrl;

    if (_imageFile != null && user != null) {
      imageUrl = await _uploadImage(_imageFile!, user.id);
      if (imageUrl == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed.')),
        );
        return;
      }
    }

    try {
      final supabase = Supabase.instance.client;
      dynamic newPost;

      if (widget.isEdit && widget.post != null) {
        await supabase.from('post').update({
          'category': _category,
          'post_type': _postType,
          'title': _titleController.text,
          'description': _descController.text,
          'image_url': imageUrl,
        }).eq('id', widget.post!['id']);
      } else {
        // CREATE
        final response = await supabase
            .from('post')
            .insert({
              'category': _category,
              'post_type': _postType,
              'title': _titleController.text,
              'description': _descController.text,
              'user_id': user?.id,
              'image_url': imageUrl,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        newPost = response;

        // Notify other users who posted opposite type in same category
        String oppositePostType = (_postType == 'Lost') ? 'Found' : 'Lost';

        final matchingPosts = await supabase
            .from('post')
            .select('user_id, title')
            .eq('category', _category as Object)
            .eq('post_type', oppositePostType)
            .neq('user_id', user?.id ?? '');

        final seenUserIds = <String>{};

        for (final post in matchingPosts) {
          final userId = post['user_id'] as String;
          if (!seenUserIds.contains(userId)) {
            seenUserIds.add(userId);
            await supabase.from('notifications').insert({
              'user_id': userId,
              'post_id': newPost['id'],
              'message': 'New $_postType post in category "$_category" matching your $oppositePostType post: "${post['title']}"',
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      setState(() => _isLoading = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Success', style: TextStyle(color: AppColors.maroon)),
          content: Text(widget.isEdit
              ? 'Post Updated Successfully!'
              : 'Post Created Successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text('OK', style: TextStyle(color: AppColors.maroon)),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      print('Insert/Update exception: $e');
      print('Stack: $stack');
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Post' : 'Create New Post',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon),
        ),
        elevation: 0,
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.maroon),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(18),
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: ['Electronics', 'Clothing', 'Documents', 'Personal Items']
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _category = value),
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _postType,
                        decoration: InputDecoration(
                          labelText: 'Post Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: ['Lost', 'Found']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(
                                        type == 'Lost' ? Icons.search : Icons.find_in_page,
                                        size: 18,
                                        color: type == 'Lost'
                                            ? AppColors.maroon
                                            : AppColors.yellow,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(type),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _postType = value),
                        validator: (value) =>
                            value == null ? 'Please select post type' : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Item Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter item title' : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: 4,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 170,
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gray),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity),
                                )
                              : _existingImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                                    )
                                  : const Center(child: Text('Tap to select an image')),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitAd,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(widget.isEdit ? 'Update Post' : 'Create Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 86, 26, 21),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
