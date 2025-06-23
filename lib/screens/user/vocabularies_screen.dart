import 'package:flutter/material.dart';
import 'package:kronk/widgets/navbar.dart';

class VocabulariesScreen extends StatefulWidget {
  const VocabulariesScreen({super.key});

  @override
  State<VocabulariesScreen> createState() => _VocabulariesScreenState();
}

class _VocabulariesScreenState extends State<VocabulariesScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('Vocabularies Screen'),
          ],
        ),
      ),
      bottomNavigationBar: Navbar(),
    );
  }
}
