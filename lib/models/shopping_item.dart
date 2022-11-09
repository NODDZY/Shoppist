class ShoppingItem {
  final String _name;
  bool _checked = false;

  ShoppingItem(this._name);

  // Getters
  String get name => _name;
  bool get isChecked => _checked; 

  // Setters
  set setChecked(bool checked) => _checked = checked;

  // Methods
  @override
  String toString() {
    return "ShoppingItem{name:$_name,checked:$_checked}";
  }

  // JSON
  Map<String, dynamic> toJson() => {
    'description':_name,
    'checked':_checked,
  };
  ShoppingItem.fromJson(Map<String, dynamic> json) :
      _name = json['description'],
      _checked = json['checked'];
}