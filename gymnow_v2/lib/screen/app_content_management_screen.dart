import 'package:flutter/material.dart';

class AppContentManagementScreen extends StatefulWidget {
  const AppContentManagementScreen({super.key});
  @override
  AppContentManagementScreenState createState() => AppContentManagementScreenState();
}

class AppContentManagementScreenState extends State<AppContentManagementScreen> {
  List<String> contentList = ['Workout Tips', 'Dietary Advice', 'Motivational Quotes'];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App Content Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Add New Content',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addContent,
              child: Text('Add Content'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: contentList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(contentList[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeContent(index),
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

  void _addContent() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        contentList.add(_controller.text);
        _controller.clear();
      });
    }
  }

  void _removeContent(int index) {
    setState(() {
      contentList.removeAt(index);
    });
  }
}
