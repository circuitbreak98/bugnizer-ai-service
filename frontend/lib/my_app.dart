// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  final String baseUrl = "http://localhost:8000";

  Future<Map<String, dynamic>> classifyBug(
      String title, String description) async {
    final url = Uri.parse('$baseUrl/triage');
    final body = <String, String>{};
    if (title.isNotEmpty) body['title'] = title;
    if (description.isNotEmpty) body['description'] = description;
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: jsonEncode(body));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to classify bug: ${response.statusCode}');
    }
  }
}

final bugTriageProvider =
    StateNotifierProvider<BugTriageNotifier, AsyncValue<Map<String, dynamic>?>>(
        (ref) {
  final api = ref.watch(apiClientProvider);
  return BugTriageNotifier(api);
});

class BugTriageNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final ApiClient api;
  BugTriageNotifier(this.api) : super(const AsyncValue.data(null));

  Future<void> classifyBug(String title, String description) async {
    try {
      state = const AsyncValue.loading();
      final result = await api.classifyBug(title, description);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class BugTriagePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final triageState = ref.watch(bugTriageProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Bug Triage')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Title (optional)")),
            TextField(
                controller: descController,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 4),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final desc = descController.text.trim();
                ref.read(bugTriageProvider.notifier).classifyBug(title, desc);
              },
              child: Text('Submit'),
            ),
            SizedBox(height: 24),
            triageState.when(
              data: (result) {
                if (result == null) {
                  return Text('Enter bug details and press Submit to triage.');
                }
                final category = result['category'];
                final confidence = result['confidence'];
                return Text(
                  'Predicted Category: $category\nConfidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                );
              },
              loading: () => CircularProgressIndicator(),
              error: (error, stack) => Text(
                'Error: ${error.toString()}',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
