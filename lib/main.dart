import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:convert';

import 'models/shopping_item.dart';
import 'models/shopping_list.dart';
import 'utility/file_manager.dart';

enum DialogResult { cancel, approve, add }
const String appName = "Shoppist";

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override 
  HomeScreenState createState() => HomeScreenState();
}

// Widget representing our home screen with all widgets and logic
class HomeScreenState extends State<HomeScreen> {
  final TextEditingController editController = TextEditingController();
  final FocusNode fNode = FocusNode();

  final List<ShoppingList> _lists = [];   // This contains all of our loaded lists
  int _selectedList = -1;                 // The id of the selected list
  String _addItemInput = "";              // Inpup in textfield for adding items

  @override
  void initState() {
    log("initState(): Trying to load stored lists");
    // Initialize app by reading any saved data
    FileManager.readIndicies().then((value) {
      try {
        log("initState(): Indices: ${value!}");
        List<int> ids = List<int>.from(json.decode(value));
        if (ids.isNotEmpty) { _selectedList = ids[0]; }
        for (int id in ids) {
          FileManager.readFile(id).then((value) {
            if (value != null) {
              log("initState(): Found: ${ShoppingList.fromJson(jsonDecode(value)).toString()}");
              setState(() {_lists.add(ShoppingList.fromJson(jsonDecode(value)));});
            }
          });
        }
        setState(() {});
      } catch (e) {
        log(e.toString());
        FileManager.writeIndicies([]);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Variables that needs to be updated every time the state is refreshed should go here:
    int listIndex = _lists.indexWhere((list) => list.id == _selectedList);  // The index in _lists of the currently selcted list
    int itemCount; if (listIndex == -1) {itemCount = 0;} else {itemCount = _lists[listIndex].length;} // Amount of items in the _lists[listIndex]
    String creatingListTitle = '';  // Temporary variable when making a new list

    return Scaffold(
      appBar: AppBar(title: const Text(appName)),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // FIXME: These children should be split into classes (Stateful Widgets). TODO: Figure out how to update ui/state from other classes/widgets...
            // At the top of our homescreen we can select what list to view
            Row(
              children: [
                Expanded(
                  child: 
                    DropdownButton(
                      value: _selectedList,
                      items: List.generate(
                        _lists.length, 
                        (index) => DropdownMenuItem(
                          value: _lists[index].id,
                          child: Text(_lists[index].title)
                        )
                      ),
                      onChanged: (value) {
                        setState(() {
                          log("ListSelector: Selection changed to id=$value");
                          _selectedList = value!;
                        });
                      },
                      hint: const Text("Select list"),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      iconEnabledColor: Colors.green,
                    )
                ),
                IconButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(60, 55),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Add new list'),
                        content: TextField(
                          autofocus: true,
                          onSubmitted: (value) {
                            Navigator.pop(context, value);
                          },
                          onChanged: (value) => creatingListTitle = value,
                          decoration: const InputDecoration(
                            hintText: 'Enter name of new list',
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context, DialogResult.cancel),
                            ),
                          TextButton(
                            child: const Text('Add'),
                            onPressed: () {
                              if (creatingListTitle.isEmpty) { return; }
                              else { Navigator.pop(context, creatingListTitle); }
                            },
                          ),
                        ],
                      );
                    },
                  ).then((value) async {
                    if(value != DialogResult.cancel) {
                      int id = _lists.length; for (ShoppingList e in _lists) { if (e.id == id) {id++;} }
                      ShoppingList newList = ShoppingList(value, id);
                      log("_addNewListDialog(): New list created: ($id) $value");
                      FileManager.writeFile(newList.toJson(), newList.id);
                      setState(() {
                        _selectedList = id;
                        _lists.add(newList);
                      });
                      FileManager.writeIndicies(_lists.map((element) => element.id).toList());
                    } else {log("_addNewListDialog(): List creation canceled");}
                  }),
                  icon: const Icon(Icons.add)
                ),
                IconButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(60, 55),
                    shape: const CircleBorder(),
                  ),
                  onPressed: listIndex == -1 ? null : () => {
                    if (_lists.isNotEmpty && _selectedList != -1 && listIndex != -1) {
                      showDialog<DialogResult>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Delete ${_lists[listIndex].title}'),
                            content: Text('Are you sure you want to delete ${_lists[listIndex].title}?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('No'),
                                onPressed: () => Navigator.pop(context, DialogResult.cancel),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context, DialogResult.approve),
                                child: const Text('Yes'),
                              ),
                            ],
                          );
                        },
                      ).then((value) {
                        if(value == DialogResult.approve) {
                          log("_removeListDialog(): List ($_selectedList) ${_lists[listIndex].title} at index $listIndex removed");
                          ShoppingList deleted = _lists.removeAt(listIndex);
                          setState(() {
                            if (_lists.isEmpty) { _selectedList = -1; }
                            else { _selectedList = _lists[0].id; }
                          });
                          FileManager.deleteFile(deleted.id);
                          FileManager.writeIndicies(_lists.map((element) => element.id).toList());
                        } else {log("_removeListDialog(): List deletion canceled");}
                      },)
                    } else { log("_removeListDialog(): Tried to delete nothing") }
                  },
                  icon: const Icon(Icons.remove)
                )
            ]),

            const Divider(color: Colors.white),

            // Next is a textfield where the user can add items to the selected list
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    enabled: listIndex != -1,
                    controller: editController,
                    focusNode: fNode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Add item to list..."
                    ),
                    onChanged: (text) {
                      _addItemInput = text;
                    },
                    onFieldSubmitted: (text) {
                      setState(() {
                        _lists[listIndex].items.insert(0, ShoppingItem(text));
                        editController.clear();
                        fNode.requestFocus();
                      });
                      FileManager.writeFile(_lists[listIndex].toJson(), _lists[listIndex].id);
                      log("TextFormField: Item $text added to ($_selectedList) ${_lists[listIndex].title}");
                    },
                  ),
                ),
                TextButton(
                  onPressed: listIndex == -1 ? null : (() {
                    setState(() {
                      _lists[listIndex].items.insert(0, ShoppingItem(_addItemInput));
                      editController.clear();
                      });
                    log("TextFormField (Button): Item $_addItemInput added to ($_selectedList) ${_lists[listIndex].title}");
                    FileManager.writeFile(_lists[listIndex].toJson(), _lists[listIndex].id);
                    }),
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(60, 55),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                )
              ],
            ),

            const Divider(height: 50),

            // Next is the list itself
            // TODO: Longpress to remove/move item (GestureDetector Widget)
            Expanded(
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: ((context, index) {
                  return Row(
                    children: [
                      Checkbox(
                        value: _lists[listIndex].items[index].isChecked,
                        onChanged: (newValue) {
                          bool checked = _lists[listIndex].items[index].isChecked;
                          log("Checkbox: Setting ${_lists[listIndex].items[index]} to checked=${!checked}");
                          int lastUncheckedIndex = 0;
                          for (ShoppingItem i in _lists[listIndex].items) { if (!i.isChecked) {lastUncheckedIndex++;}}
                          if (checked) {
                            _lists[listIndex].setItemChecked(index, false);
                            ShoppingItem removed = _lists[listIndex].removeItem(index);
                            setState(() {
                              _lists[listIndex].items.insert(lastUncheckedIndex, removed);
                            });
                          } 
                          else {
                            _lists[listIndex].setItemChecked(index, true);
                            ShoppingItem removed = _lists[listIndex].removeItem(index);
                            setState(() {
                              _lists[listIndex].items.insert(lastUncheckedIndex-1, removed);
                            });
                          }
                          FileManager.writeFile(_lists[listIndex].toJson(), _lists[listIndex].id);
                        },
                      ),
                      Text(_lists[listIndex].items[index].name,)
                    ],
                  );
                })
              )
            )
          ],
        )
      )
    );
  }
}