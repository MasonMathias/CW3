import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CW3',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _mode,
      home: MyHomePage(title: 'CW3', onToggleTheme: _toggleTheme),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.onToggleTheme,
  });

  final String title;
  final VoidCallback onToggleTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<_Task> _tasks = [_Task('1'), _Task('2', done: true), _Task('3')];

  final _newTaskCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _newTaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // List
            Container(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 380),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(blurRadius: 8, color: Color(0x22000000)),
                ],
              ),
              child: Scrollbar(
                child: ListView.separated(
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 2),
                  itemBuilder: (context, i) {
                    final t = _tasks[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        t.name,
                        style: t.done
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Checkbox
                          Checkbox(
                            value: t.done,
                            onChanged: (v) {
                              setState(() => t.done = v ?? false);
                              _saveTasks();
                            },
                          ),

                          // Delete button
                          Tooltip(
                            message: 'Delete',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                              ),
                              onPressed: () => _removeAt(i),
                              child: const Icon(Icons.remove),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Text box
            SizedBox(
              width: 360,
              child: TextField(
                controller: _newTaskCtrl,
                decoration: const InputDecoration(
                  hintText: 'New task',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _addFromBox(),
              ),
            ),

            // Buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _addFromBox, child: Icon(Icons.add)),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _toggleTheme,
                  child: Icon(Icons.dark_mode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTasks() async {
    final sp = await SharedPreferences.getInstance();
    final ok = await sp.setString(
      'tasks',
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
    if (!ok) debugPrint('prefs save failed');
  }

  Future<void> _loadTasks() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('tasks');
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      final items = decoded
          .map((e) => _Task.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() {
        _tasks
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      debugPrint('prefs parse error: $e');
    }
  }

  void _addFromBox() {
    final name = _newTaskCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _tasks.add(_Task(name)));
    _newTaskCtrl.clear();
    _saveTasks();
  }

  void _removeAt(int index) {
    setState(() => _tasks.removeAt(index));
    _saveTasks();
  }

  void _toggleTheme() {
    widget.onToggleTheme();
  }
}

class _Task {
  String name;
  bool done;
  _Task(this.name, {this.done = false});

  Map<String, dynamic> toJson() => {'name': name, 'done': done};
  factory _Task.fromJson(Map<String, dynamic> m) =>
      _Task(m['name'] as String, done: m['done'] as bool? ?? false);
}
