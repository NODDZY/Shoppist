import 'dart:convert';
import 'package:xlist/models/shopping_item.dart';

class ShoppingList {
  List<ShoppingItem> _items = [];
  final String _title;
  final int _id;

  ShoppingList(this._title, this._id);

  // Getters
  String get title => _title;
  int get id => _id;
  List<ShoppingItem> get items => _items;
  int get length => _items.length;

  // Setters
  set setGroceryList(List<ShoppingItem> groceries) => _items = groceries; 

  // Methods
  void addItem(ShoppingItem item) => _items.add(item);
  bool isItemChecked(int index) => _items[index].isChecked;
  void setItemChecked(int index, bool state) => _items[index].setChecked = state;
  ShoppingItem removeItem(int index) => _items.removeAt(index);

  @override
  String toString() {
    return "ShoppingList{title:$_title,id:$_id,items:$_items}";
  }

  // JSON
  Map<String, dynamic> toJson() => {
    'title':_title,
    'id':_id,
    'items':jsonEncode(_items),
  };
  ShoppingList.fromJson(Map<String, dynamic> json) : 
    _title = json['title'],
    _id = json['id'],
    _items = List<ShoppingItem>.from(jsonDecode(json['items']).map((model) => ShoppingItem.fromJson(model)));
}