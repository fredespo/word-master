import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _buildImportButton(),
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return ElevatedButton(
      onPressed: () async {
        String functionUrl =
            "https://rgnbhyf5h63zg2krd6mxtr7cga0qlnse.lambda-url.us-east-1.on.aws/";
        http.Response response = await http.get(Uri.parse(functionUrl));
        print(response.body);
      },
      child: const Text('Import'),
    );
  }
}
