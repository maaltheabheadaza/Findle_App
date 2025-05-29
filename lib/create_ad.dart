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
    // If editing, pre-fill fields
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
      if (storageResponse.isEmpty) {
        print('Image upload failed: empty response');
        return null;
      }
      final publicUrl = Supabase.instance.client.storage
          .from('ad-images')
          .getPublicUrl(fileName);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> _submitAd() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    String? imageUrl = _existingImageUrl;

    // If a new image is picked, upload it
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
      if (widget.isEdit && widget.post != null) {
        // UPDATE
        await Supabase.instance.client
            .from('post')
            .update({
              'category': _category,
              'post_type': _postType,
              'title': _titleController.text,
              'description': _descController.text,
              'image_url': imageUrl,
            })
            .eq('id', widget.post!['id']);
      } else {
        // CREATE
        await Supabase.instance.client
            .from('post')
            .insert({
              'category': _category,
              'post_type': _postType,
              'title': _titleController.text,
              'description': _descController.text,
              'user_id': user?.id,
              'image_url': imageUrl,
              'created_at': DateTime.now().toIso8601String(),
            });
      }
      setState(() => _isLoading = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            widget.isEdit ? 'Success' : 'Success',
            style: TextStyle(color: AppColors.maroon),
          ),
          content: Text(widget.isEdit
              ? 'Post Updated Successfully!'
              : 'Post Created Successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Return true to refresh
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
                      // Category Dropdown
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
                      // Post Type Dropdown
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
                      // Title
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
                      // Description
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
                      // Image Picker
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
                              : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(_existingImageUrl!, fit: BoxFit.cover, width: double.infinity),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.add_a_photo, size: 38, color: AppColors.gray),
                                          SizedBox(height: 8),
                                          Text('Tap to add image', style: TextStyle(color: AppColors.gray)),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Create/Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.maroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    await _submitAd();
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.yellow,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.isEdit ? 'Update Post' : 'Post',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                    color: AppColors.yellow,
                                  ),
                                ),
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