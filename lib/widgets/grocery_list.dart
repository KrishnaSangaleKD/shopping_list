import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = false;
  String _error = '';
  FToast fToast = FToast();

  @override
  void initState() {
    fToast.init(context);
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https(
      'grocery-shopping-66045-default-rtdb.firebaseio.com',
      'shopping_list.json',
    );
    final response = await http.get(url);
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'An error occurred';
      });
    }
    // ignore: unnecessary_null_comparison
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    var newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );
    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    final url = Uri.https('grocery-shopping-66045-default-rtdb.firebaseio.com',
        'shopping_list/${item.id}.json');
    final resp = await http.delete(url);
    if (resp.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    } else {
      _groceryItems.remove(item);
      fToast.showToast(
        child: const Text('Item removed'),
        gravity: ToastGravity.BOTTOM,
        toastDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: CircularProgressIndicator(),
    );

    if (!_isLoading) {
      if (_groceryItems.isEmpty) {
        content = const Center(
          child: Text('No items added yet!'),
        );
      }
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemBuilder: (context, index) {
          return Dismissible(
            onDismissed: (direction) {
              _removeItem(_groceryItems[index]);
            },
            key: ValueKey(_groceryItems[index].id),
            child: ListTile(
              title: Text(_groceryItems[index].name),
              leading: Container(
                width: 24,
                height: 24,
                color: _groceryItems[index].category.color,
              ),
              trailing: Text(
                _groceryItems[index].quantity.toString(),
              ),
            ),
          );
        },
        itemCount: _groceryItems.length,
        padding: const EdgeInsets.all(16.0),
      );
    }

    if (_error.isNotEmpty) {
      content = Center(
        child: Text(_error),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          ),
        ],
      ),
      body: content,
    );
  }
}
