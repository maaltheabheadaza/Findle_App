import 'package:flutter/material.dart';
import 'main.dart';

class LostAndFoundPage extends StatefulWidget {
  @override
  _LostAndFoundPageState createState() => _LostAndFoundPageState();
}

class _LostAndFoundPageState extends State<LostAndFoundPage> {
  final List<Map<String, String>> _items = [
    {'title': 'Lost Wallet', 'description': 'Black leather wallet near library'},
    {'title': 'Found Keys', 'description': 'Set of keys found at cafeteria'},
    {'title': 'Lost Phone', 'description': 'White smartphone lost in park'},
    {'title': 'Found Jacket', 'description': 'Blue jacket found in classroom'},
  ];

  List<Map<String, String>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = _items;
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _items
          .where((item) =>
              item['title']!.toLowerCase().contains(query) ||
              item['description']!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterList);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lost & Found Items'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search items...',
                prefixIcon: Icon(Icons.search, color: AppColors.maroon),
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'No items found.',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.gray,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          child: ListTile(
                            leading: Icon(Icons.inventory, color: AppColors.maroon),
                            title: Text(
                              item['title']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(item['description']!),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // You can add detail page or popup here
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
