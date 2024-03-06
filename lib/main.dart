import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Panda Todo',
      theme: new ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: new HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class TodoItem {
  String title;
  bool done;

  TodoItem({required this.title, required this.done});

  toJSONEncodable() {
    Map<String, dynamic> m = new Map();

    m['title'] = title;
    m['done'] = done;

    return m;
  }
}

class TodoList {
  List<TodoItem> items = [];

  toJSONEncodable() {
    return items.map((item) {
      return item.toJSONEncodable();
    }).toList();
  }
}

class _MyHomePageState extends State<HomePage> {
  final TodoList list = new TodoList();
  final LocalStorage storage = new LocalStorage('todo_app.json');
  bool initialized = false;
  TextEditingController controller = new TextEditingController();

  _toggleItem(TodoItem item) {
    setState(() {
      item.done = !item.done;
      _saveToStorage();
    });
  }

  _addItem(String title) {
    setState(() {
      final item = new TodoItem(title: title, done: false);
      list.items.add(item);
      _saveToStorage();
    });
  }

  _saveToStorage() {
    storage.setItem('todos', list.toJSONEncodable());
  }

  _clearStorage() async {
    await storage.clear();

    setState(() {
      list.items = storage.getItem('todos') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/panda.jpg',
              height: 70,
            ),
            SizedBox(width: 10),
            Text('Panda ToDo'),
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        constraints: BoxConstraints.expand(),
        child: FutureBuilder(
          future: storage.ready,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!initialized) {
              var items = storage.getItem('todos');

              if (items != null) {
                list.items = List<TodoItem>.from(
                  (items as List).map(
                    (item) => TodoItem(
                      title: item['title'],
                      done: item['done'],
                    ),
                  ),
                );
              }

              initialized = true;
            }

            return Column(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.items.length,
                    itemBuilder: (BuildContext context, int index) {
                      return CheckboxListTile(
                        value: list.items[index].done,
                        title: Text(
                          list.items[index].title,
                          style: TextStyle(
                            decoration: list.items[index].done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        onChanged: (_) {
                          _toggleItem(list.items[index]);
                        },
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return Divider();
                    },
                  ),
                ),
                ListTile(
                  title: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'What to do?',
                      border: OutlineInputBorder(),
                    ),
                    onEditingComplete: _save,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.save),
                        onPressed: _save,
                        tooltip: 'Save',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: _clearStorage,
                        tooltip: 'Clear storage',
                      )
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _save() {
    _addItem(controller.value.text);
    controller.clear();
  }
}
