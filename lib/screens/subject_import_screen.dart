import 'package:flutter/material.dart';

class SubjectImportScreen extends StatefulWidget {
  const SubjectImportScreen({super.key});

  @override
  State<SubjectImportScreen> createState() => _SubjectImportScreenState();
}

class _SubjectImportScreenState extends State<SubjectImportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import subject'),
      ),
      body: const SafeArea(child: SizedBox.expand()),
    );
  }
}
